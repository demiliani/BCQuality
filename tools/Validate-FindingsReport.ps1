<#
.SYNOPSIS
    Validates a BCQuality findings-report against its structural and semantic contract.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $ReportPath,
    [string] $BCQualityRoot,
    [string] $SourceRoot,
    [string[]] $SourcePaths = @(),
    [string[]] $RetrievedArticlePaths = @(),
    [ValidateSet('leaf', 'super')]
    [string] $SkillKind = 'leaf',
    [switch] $AllowBoundedNormalization
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $BCQualityRoot) {
    $BCQualityRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
}
$BCQualityRoot = (Resolve-Path -LiteralPath $BCQualityRoot).Path
$schemaPath = Join-Path $BCQualityRoot 'schemas/findings-report.schema.json'
$raw = Get-Content -LiteralPath $ReportPath -Raw
try {
    if (-not ($raw | Test-Json -SchemaFile $schemaPath -ErrorAction Stop)) {
        throw 'Report does not satisfy schemas/findings-report.schema.json.'
    }
    $report = $raw | ConvertFrom-Json -Depth 100
}
catch {
    throw "Invalid findings-report JSON or schema: $($_.Exception.Message)"
}

$retrieved = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($path in $RetrievedArticlePaths) {
    $retrieved.Add($path) | Out-Null
}
$sources = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($path in $SourcePaths) {
    $sources.Add($path) | Out-Null
}
$lineCounts = @{}

function Test-HasProperty {
    param([object] $Object, [string] $Name)
    return $null -ne $Object -and $Object.PSObject.Properties.Name -ccontains $Name
}

function Get-SourceLineCount {
    param([string] $Path)

    if ($lineCounts.ContainsKey($Path)) {
        return $lineCounts[$Path]
    }
    if (-not $SourceRoot) {
        return -1
    }
    $fullPath = Join-Path $SourceRoot ($Path -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        return -1
    }
    $lineCounts[$Path] = [IO.File]::ReadAllLines($fullPath).Count
    return $lineCounts[$Path]
}

function Get-SemanticErrors {
    param(
        [object] $Candidate,
        [switch] $PermitRangeStartMismatch
    )

    $errors = [Collections.Generic.List[object]]::new()
    function Add-Error {
        param([string] $Code, [string] $Path, [string] $Message)
        $errors.Add([pscustomobject]@{ Code = $Code; Path = $Path; Message = $Message }) | Out-Null
    }

    function Get-DerivedSuperOutcome {
        param([object[]] $SubResults)

        if (-not $SubResults.Count) {
            return 'not-applicable'
        }

        $outcomes = @($SubResults | ForEach-Object { $_.outcome })
        if (-not @($outcomes | Where-Object { $_ -cne 'failed' }).Count) {
            return 'failed'
        }
        if (($outcomes -ccontains 'partial') -or
            (($outcomes -ccontains 'failed') -and @($outcomes | Where-Object { $_ -cne 'failed' }).Count)) {
            return 'partial'
        }
        if (-not @($outcomes | Where-Object { $_ -cne 'not-applicable' }).Count) {
            return 'not-applicable'
        }
        if (($outcomes -ccontains 'no-knowledge') -and
            -not @($outcomes | Where-Object { $_ -cnotin @('no-knowledge', 'not-applicable') }).Count) {
            return 'no-knowledge'
        }
        return 'completed'
    }

    function Get-RolledFindingId {
        param([object] $Finding, [string] $ProducerId)

        if (@($Finding.references).Count) {
            return $Finding.id
        }
        return "${ProducerId}:$($Finding.id)"
    }

    function Test-RolledFindingMatches {
        param([object] $RolledFinding, [object] $LeafFinding, [string] $ProducerId)

        if ($RolledFinding.id -cne (Get-RolledFindingId $LeafFinding $ProducerId)) {
            return $false
        }
        foreach ($name in 'severity', 'message', 'confidence', 'domain', 'suggested-code', 'suggested-code-omission-reason') {
            $rolledHasProperty = Test-HasProperty $RolledFinding $name
            $leafHasProperty = Test-HasProperty $LeafFinding $name
            if ($rolledHasProperty -ne $leafHasProperty -or
                ($rolledHasProperty -and $RolledFinding.$name -cne $LeafFinding.$name)) {
                return $false
            }
        }

        $rolledHasLocation = Test-HasProperty $RolledFinding 'location'
        $leafHasLocation = Test-HasProperty $LeafFinding 'location'
        if ($rolledHasLocation -ne $leafHasLocation) {
            return $false
        }
        if ($rolledHasLocation) {
            if ($RolledFinding.location.file -cne $LeafFinding.location.file -or
                $RolledFinding.location.line -ne $LeafFinding.location.line) {
                return $false
            }
            $rolledHasRange = Test-HasProperty $RolledFinding.location 'range'
            $leafHasRange = Test-HasProperty $LeafFinding.location 'range'
            if ($rolledHasRange -ne $leafHasRange -or
                ($rolledHasRange -and
                    ($RolledFinding.location.range.'start-line' -ne $LeafFinding.location.range.'start-line' -or
                     $RolledFinding.location.range.'end-line' -ne $LeafFinding.location.range.'end-line'))) {
                return $false
            }
        }

        $rolledReferences = @($RolledFinding.references)
        $leafReferences = @($LeafFinding.references)
        if ($rolledReferences.Count -ne $leafReferences.Count) {
            return $false
        }
        for ($index = 0; $index -lt $rolledReferences.Count; $index++) {
            if ($rolledReferences[$index].path -cne $leafReferences[$index].path) {
                return $false
            }
            $rolledHasSha = Test-HasProperty $rolledReferences[$index] 'sha'
            $leafHasSha = Test-HasProperty $leafReferences[$index] 'sha'
            if ($rolledHasSha -ne $leafHasSha -or
                ($rolledHasSha -and $rolledReferences[$index].sha -cne $leafReferences[$index].sha)) {
                return $false
            }
        }
        return $true
    }

    function Test-Report {
        param(
            [object] $Current,
            [string] $ReportPathPrefix,
            [ValidateSet('leaf', 'super')]
            [string] $CurrentSkillKind
        )

        $findings = @($Current.findings)
        foreach ($severity in 'blocker', 'major', 'minor', 'info') {
            $actual = @($findings | Where-Object severity -CEQ $severity).Count
            if ($Current.summary.counts.$severity -ne $actual) {
                Add-Error 'COUNT_MISMATCH' "$ReportPathPrefix.summary.counts.$severity" "Expected $actual."
            }
        }
        $worklistSize = $Current.summary.coverage.'worklist-size'
        $itemsEvaluated = $Current.summary.coverage.'items-evaluated'
        if ($itemsEvaluated -gt $worklistSize) {
            Add-Error 'COVERAGE_INVALID' "$ReportPathPrefix.summary.coverage" 'items-evaluated exceeds worklist-size.'
        }
        elseif ($Current.outcome -ceq 'completed' -and $itemsEvaluated -ne $worklistSize) {
            Add-Error 'COMPLETED_COVERAGE_INCOMPLETE' "$ReportPathPrefix.summary.coverage" 'A completed report must evaluate its full worklist.'
        }
        elseif ($CurrentSkillKind -ceq 'leaf' -and $Current.outcome -ceq 'partial' -and
            ($itemsEvaluated -le 0 -or $itemsEvaluated -ge $worklistSize)) {
            Add-Error 'PARTIAL_COVERAGE_INVALID' "$ReportPathPrefix.summary.coverage" 'A partial report must evaluate a non-zero proper subset of its worklist.'
        }

        $hasSubResults = Test-HasProperty $Current 'sub-results'
        $hasSkippedSubSkills = Test-HasProperty $Current 'skipped-sub-skills'
        if ($CurrentSkillKind -ceq 'leaf') {
            if ($hasSubResults -or $hasSkippedSubSkills) {
                Add-Error 'LEAF_COMPOSITION_INVALID' $ReportPathPrefix 'A leaf report must not contain sub-results or skipped-sub-skills.'
            }
        }
        elseif (-not $hasSubResults) {
            Add-Error 'SUPER_SUB_RESULTS_REQUIRED' $ReportPathPrefix 'A super-skill report must contain sub-results.'
        }

        for ($index = 0; $index -lt $findings.Count; $index++) {
            $finding = $findings[$index]
            $findingPath = "$ReportPathPrefix.findings[$index]"
            $references = @($finding.references)
            $hasProducer = Test-HasProperty $finding 'from-sub-skill'
            if ($CurrentSkillKind -ceq 'leaf' -and $hasProducer) {
                Add-Error 'LEAF_PRODUCER_INVALID' "$findingPath.from-sub-skill" 'A leaf finding must not contain from-sub-skill.'
            }
            elseif ($CurrentSkillKind -ceq 'super' -and -not $hasProducer) {
                Add-Error 'SUPER_PRODUCER_REQUIRED' $findingPath 'A super-skill finding must identify its producer in from-sub-skill.'
            }
            if (-not $references.Count) {
                if ($finding.id -cnotmatch '(^|:)agent:[a-z0-9]+(?:-[a-z0-9]+)*$') {
                    Add-Error 'AGENT_ID_INVALID' "$findingPath.id" 'An agent finding id must contain an agent: slug marker.'
                }
                if ($finding.confidence -ceq 'high') {
                    Add-Error 'AGENT_CONFIDENCE_INVALID' "$findingPath.confidence" 'Agent confidence cannot be high.'
                }
                if ($finding.severity -cin @('blocker', 'major')) {
                    Add-Error 'AGENT_SEVERITY_INVALID' "$findingPath.severity" 'Agent severity cannot exceed minor.'
                }
            }
            else {
                if ($finding.id -cne $references[0].path) {
                    Add-Error 'PRIMARY_REFERENCE_MISMATCH' "$findingPath.id" 'Finding id must equal the primary reference path.'
                }
                foreach ($reference in $references) {
                    if ($reference.path -cnotmatch '^(microsoft|community|custom)/knowledge/.+\.md$') {
                        Add-Error 'REFERENCE_PATH_INVALID' "$findingPath.references" "Invalid knowledge path '$($reference.path)'."
                        continue
                    }
                    if (-not (Test-Path -LiteralPath (Join-Path $BCQualityRoot $reference.path) -PathType Leaf)) {
                        Add-Error 'REFERENCE_MISSING' "$findingPath.references" "Knowledge path '$($reference.path)' does not exist."
                    }
                    if (-not $retrieved.Contains($reference.path)) {
                        Add-Error 'REFERENCE_NOT_RETRIEVED' "$findingPath.references" "Knowledge path '$($reference.path)' was not retrieved in full."
                    }
                }
            }

            if (Test-HasProperty $finding 'location') {
                $location = $finding.location
                if (-not $sources.Contains($location.file)) {
                    Add-Error 'SOURCE_OUT_OF_SCOPE' "$findingPath.location.file" "Source path '$($location.file)' is outside the supplied scope."
                }
                $lineCount = Get-SourceLineCount $location.file
                if ($lineCount -lt 0) {
                    Add-Error 'SOURCE_MISSING' "$findingPath.location.file" "Source path '$($location.file)' does not exist."
                }
                elseif ($location.line -gt $lineCount) {
                    Add-Error 'SOURCE_LINE_INVALID' "$findingPath.location.line" "Line exceeds the file's $lineCount lines."
                }

                if (Test-HasProperty $location 'range') {
                    $range = $location.range
                    if ($range.'start-line' -ne $location.line) {
                        Add-Error 'RANGE_START_MISMATCH' "$findingPath.location.range.start-line" 'start-line must equal line.'
                    }
                    if ($range.'end-line' -lt $range.'start-line' -or
                        ($lineCount -ge 0 -and $range.'end-line' -gt $lineCount)) {
                        Add-Error 'SOURCE_RANGE_INVALID' "$findingPath.location.range" 'Range is reversed or exceeds the source file.'
                    }
                }
            }
        }

        if ($CurrentSkillKind -ceq 'super' -and $hasSubResults) {
            $subResults = @($Current.'sub-results')
            for ($index = 0; $index -lt $subResults.Count; $index++) {
                Test-Report $subResults[$index] "$ReportPathPrefix.sub-results[$index]" 'leaf'
            }

            $expectedOutcome = Get-DerivedSuperOutcome $subResults
            if ($Current.outcome -cne $expectedOutcome) {
                Add-Error 'SUPER_OUTCOME_MISMATCH' "$ReportPathPrefix.outcome" "Expected '$expectedOutcome' from sub-results."
            }

            $includedSubResults = @($subResults | Where-Object outcome -CNE 'failed')
            $expectedWorklistSize = ($includedSubResults | Measure-Object -Property { $_.summary.coverage.'worklist-size' } -Sum).Sum
            $expectedItemsEvaluated = ($includedSubResults | Measure-Object -Property { $_.summary.coverage.'items-evaluated' } -Sum).Sum
            if ($null -eq $expectedWorklistSize) { $expectedWorklistSize = 0 }
            if ($null -eq $expectedItemsEvaluated) { $expectedItemsEvaluated = 0 }
            if ($worklistSize -ne $expectedWorklistSize -or $itemsEvaluated -ne $expectedItemsEvaluated) {
                Add-Error 'SUPER_COVERAGE_MISMATCH' "$ReportPathPrefix.summary.coverage" `
                    "Expected worklist-size $expectedWorklistSize and items-evaluated $expectedItemsEvaluated from non-failed sub-results."
            }

            $failedProducerIds = @($subResults | Where-Object outcome -CEQ 'failed' | ForEach-Object { $_.skill.id })
            $eligibleFindingsById = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
            foreach ($subResult in $includedSubResults) {
                foreach ($finding in @($subResult.findings)) {
                    $rolledId = Get-RolledFindingId $finding $subResult.skill.id
                    if (-not $eligibleFindingsById.ContainsKey($rolledId)) {
                        $eligibleFindingsById[$rolledId] = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
                    }
                    $eligibleFindingsById[$rolledId].Add([string]$subResult.skill.id) | Out-Null
                }
            }

            $validRolledIds = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            for ($index = 0; $index -lt $findings.Count; $index++) {
                $finding = $findings[$index]
                $producerId = [string]$finding.'from-sub-skill'
                if ($producerId -ceq 'agent') {
                    continue
                }
                if ($producerId -cin $failedProducerIds) {
                    Add-Error 'SUPER_FAILED_FINDING_LEAKAGE' "$ReportPathPrefix.findings[$index].from-sub-skill" `
                        "Finding is attributed to failed sub-skill '$producerId'."
                    continue
                }
                if (-not $eligibleFindingsById.ContainsKey($finding.id) -or
                    -not $eligibleFindingsById[$finding.id].Contains($producerId)) {
                    Add-Error 'SUPER_PRODUCER_INVALID' "$ReportPathPrefix.findings[$index].from-sub-skill" `
                        "Sub-skill '$producerId' did not emit finding '$($finding.id)' in a non-failed result."
                    continue
                }
                $producerLeafFindings = @(
                    $includedSubResults |
                        Where-Object { $_.skill.id -ceq $producerId } |
                        ForEach-Object { $_.findings } |
                        Where-Object { (Get-RolledFindingId $_ $producerId) -ceq $finding.id }
                )
                if (-not @($producerLeafFindings | Where-Object { Test-RolledFindingMatches $finding $_ $producerId }).Count) {
                    Add-Error 'SUPER_FINDING_MISMATCH' "$ReportPathPrefix.findings[$index]" `
                        "Rolled-up finding '$($finding.id)' does not preserve the finding emitted by '$producerId'."
                    continue
                }
                $validRolledIds.Add([string]$finding.id) | Out-Null
            }

            foreach ($rolledId in $eligibleFindingsById.Keys) {
                if (-not $validRolledIds.Contains($rolledId)) {
                    Add-Error 'SUPER_FINDING_MISSING' "$ReportPathPrefix.findings" `
                        "No valid rolled-up finding represents non-failed leaf finding '$rolledId'."
                }
            }
        }
    }

    Test-Report $Candidate '$' $SkillKind
    if ($PermitRangeStartMismatch) {
        return @($errors | Where-Object Code -CNE 'RANGE_START_MISMATCH')
    }
    return @($errors)
}

$errors = @(Get-SemanticErrors $report)
$normalized = $false
$removedRanges = [Collections.Generic.List[object]]::new()
if ($errors.Count -and $AllowBoundedNormalization) {
    $otherErrors = @($errors | Where-Object Code -CNE 'RANGE_START_MISMATCH')
    $rangeErrors = @($errors | Where-Object Code -CEQ 'RANGE_START_MISMATCH')
    if (-not $otherErrors.Count -and $rangeErrors.Count) {
        $candidate = $report | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100
        $eligible = $true
        foreach ($finding in @($candidate.findings)) {
            if (-not (Test-HasProperty $finding 'location') -or
                -not (Test-HasProperty $finding.location 'range') -or
                $finding.location.range.'start-line' -eq $finding.location.line) {
                continue
            }
            $range = $finding.location.range
            if ($range.'start-line' -gt $finding.location.line -or
                $finding.location.line -gt $range.'end-line' -or
                (Test-HasProperty $finding 'suggested-code')) {
                $eligible = $false
                break
            }
            $removedRanges.Add([pscustomobject]@{
                findingId = $finding.id
                file = $finding.location.file
                line = $finding.location.line
                startLine = $range.'start-line'
                endLine = $range.'end-line'
            }) | Out-Null
            $finding.location.PSObject.Properties.Remove('range')
        }
        if ($eligible -and -not @(Get-SemanticErrors $candidate).Count) {
            $report = $candidate
            $normalized = $true
            $errors = @()
        }
    }
}

if ($errors.Count) {
    $details = @($errors | ForEach-Object { "$($_.Code) at $($_.Path): $($_.Message)" }) -join '; '
    throw "Findings-report acceptance failed: $details"
}

return [pscustomobject][ordered]@{
    normalized = $normalized
    report = $report
    removedRanges = @($removedRanges)
}