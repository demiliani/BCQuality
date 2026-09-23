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

    function Test-Report {
        param([object] $Current, [string] $ReportPathPrefix)

        $findings = @($Current.findings)
        foreach ($severity in 'blocker', 'major', 'minor', 'info') {
            $actual = @($findings | Where-Object severity -CEQ $severity).Count
            if ($Current.summary.counts.$severity -ne $actual) {
                Add-Error 'COUNT_MISMATCH' "$ReportPathPrefix.summary.counts.$severity" "Expected $actual."
            }
        }
        if ($Current.summary.coverage.'items-evaluated' -gt $Current.summary.coverage.'worklist-size') {
            Add-Error 'COVERAGE_INVALID' "$ReportPathPrefix.summary.coverage" 'items-evaluated exceeds worklist-size.'
        }

        for ($index = 0; $index -lt $findings.Count; $index++) {
            $finding = $findings[$index]
            $findingPath = "$ReportPathPrefix.findings[$index]"
            $references = @($finding.references)
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

        if (Test-HasProperty $Current 'sub-results') {
            $subResults = @($Current.'sub-results')
            for ($index = 0; $index -lt $subResults.Count; $index++) {
                Test-Report $subResults[$index] "$ReportPathPrefix.sub-results[$index]"
            }
        }
    }

    Test-Report $Candidate '$'
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