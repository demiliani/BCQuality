<#
.SYNOPSIS
    Renders a feature-design report (JSON) as a readable Markdown document.

.DESCRIPTION
    Deterministic: the same report always produces the same Markdown. Open
    questions come first, because a person must answer them before the design
    is implemented. Every design element points to the numbered knowledge
    sources it rests on. The JSON report stays the source of truth; this
    rendering adds nothing to it.

.EXAMPLE
    pwsh tools/ConvertTo-FeatureDesignMarkdown.ps1 -ReportPath design.json -OutputPath design.md
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $ReportPath,
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
$report = Get-Content -LiteralPath $ReportPath -Raw -Encoding utf8 | ConvertFrom-Json

function Format-Cell([string] $Text) {
    if (-not $Text) { return '' }
    return ($Text -replace '\|', '\|' -replace "`r?`n", ' ').Trim()
}

# Number the knowledge sources once; design elements refer to them as [n].
$sourceNumber = [ordered]@{}
$n = 0
foreach ($k in @($report.knowledge)) { $n++; $sourceNumber[$k.path] = $n }

function Format-Sources($Paths) {
    $refs = foreach ($p in @($Paths)) {
        if ($p -and $sourceNumber.Contains($p)) { "[$($sourceNumber[$p])]" }
    }
    if (-not $refs) { return 'agent judgment' }
    return ($refs -join ' ')
}

$design = $report.design
$lines = [System.Collections.Generic.List[string]]::new()
function Add([string] $Line = '') { $lines.Add($Line) }

$outcomeText = @{
    'completed'      = 'Complete design'
    'partial'        = 'Partial design: some parts could not be designed'
    'no-knowledge'   = 'No applicable BCQuality knowledge: no design produced'
    'not-applicable' = 'Not a Business Central feature request'
    'failed'         = 'Design failed'
}[$report.outcome]

Add '# Feature design'
Add
Add "> $(Format-Cell $report.summary.request)"
Add
Add "**Result:** $outcomeText. **Business process:** $((Format-Cell $report.summary.'business-process').TrimEnd('.')). **Knowledge used:** $(@($report.knowledge).Count) BCQuality articles."
if ($report.'outcome-reason') { Add; Add "**Why:** $(Format-Cell $report.'outcome-reason')" }

$questions = @($report.'open-questions')
Add
Add '## 1. Questions to answer before implementation'
Add
if ($questions.Count -eq 0) {
    Add 'None. The request settles every decision the design needs.'
} else {
    Add 'The request does not settle these points. Answer them, then approve the design.'
    Add
    $i = 0
    foreach ($q in $questions) {
        $i++
        $affects = if (@($q.affects).Count) { " _(affects: $((@($q.affects)) -join ', '))_" } else { '' }
        Add "$i. $(Format-Cell $q.question)$affects"
    }
}

Add
Add '## 2. Objects'
Add
if (@($design.objects).Count -eq 0) { Add 'No objects designed.' } else {
    Add '| # | Action | Type | Object | Purpose | Fields | Sources |'
    Add '| --- | --- | --- | --- | --- | --- | --- |'
    $i = 0
    foreach ($o in @($design.objects)) {
        $i++
        $fields = (@($o.fields) | Where-Object { $_ } | ForEach-Object {
            $f = "$($_.name) ($($_.type))"
            if ($_.note) { $f += ": $($_.note)" }
            $f
        }) -join '; '
        Add "| $i | $($o.action) | $($o.'object-type') | $(Format-Cell $o.target) | $(Format-Cell $o.purpose) | $(Format-Cell $fields) | $(Format-Sources $o.knowledge) |"
    }
}

$mechanismText = @{
    'transferfields' = 'standard TransferFields copy'
    'event-copy'     = 'copied in an event subscriber'
    'validate'       = 'field validation'
    'user-entry'     = 'entered by the user'
    'other'          = 'other'
}
Add
Add '## 3. How the data flows'
Add
if (@($design.'data-flow').Count -eq 0) { Add 'No data flow designed.' } else {
    foreach ($f in @($design.'data-flow')) {
        $note = if ($f.note) { " $(Format-Cell $f.note)" } else { '' }
        Add "- **$(Format-Cell $f.from)** → **$(Format-Cell $f.to)**: $($mechanismText[$f.mechanism]).$note $(Format-Sources $f.knowledge)"
    }
}

Add
Add '## 4. Event subscriptions'
Add
if (@($design.subscriptions).Count -eq 0) { Add 'None.' } else {
    Add '| Publisher | Event | Purpose | Rules the subscriber must follow | Sources |'
    Add '| --- | --- | --- | --- | --- |'
    foreach ($s in @($design.subscriptions)) {
        $guards = (@($s.guards) | Where-Object { $_ } | ForEach-Object { Format-Cell $_ }) -join ' · '
        Add "| $(Format-Cell $s.publisher) | ``$($s.event)`` | $(Format-Cell $s.purpose) | $guards | $(Format-Sources $s.knowledge) |"
    }
}

Add
Add '## 5. Setup, permissions and lifecycle'
Add
if (@($design.lifecycle).Count -eq 0) { Add 'Nothing beyond the objects above.' } else {
    foreach ($l in @($design.lifecycle)) {
        Add "- **$($l.concern)**: $(Format-Cell $l.step) $(Format-Sources $l.knowledge)"
    }
}

$deps = @($design.dependencies | Where-Object { $_ })
if ($deps.Count) {
    Add
    Add '## Required app dependencies'
    Add
    foreach ($dep in $deps) {
        $idText = if ($dep.id) { " (``$($dep.id)``$(if ($dep.publisher) { ", $($dep.publisher)" }))" } else { '' }
        Add "- **$(Format-Cell $dep.app)**$($idText): $(Format-Cell $dep.reason) $(Format-Sources $dep.knowledge)"
    }
}

Add
Add '## 6. Tests'
Add
if (@($design.tests).Count -eq 0) { Add 'No tests designed.' } else {
    $i = 0
    foreach ($t in @($design.tests)) {
        $i++
        Add "$i. **$($t.id)** $(Format-Sources $t.knowledge)"
        Add "    - Given $(Format-Cell $t.given)"
        Add "    - When $(Format-Cell $t.when)"
        Add "    - Then $(Format-Cell $t.then)"
    }
}

$unresolved = @($report.unresolved)
if ($unresolved.Count) {
    Add
    Add '## 7. Limits of this design'
    Add
    Add 'These points are not backed by BCQuality knowledge or could not be confirmed. Check them before relying on the design.'
    Add
    foreach ($u in $unresolved) { Add "- $(Format-Cell $u)" }
}

Add
Add '## Sources'
Add
if ($sourceNumber.Count -eq 0) { Add 'No BCQuality articles were used.' } else {
    foreach ($k in @($report.knowledge)) {
        Add "[$($sourceNumber[$k.path])] ``$($k.path)``: $(Format-Cell $k.'used-for')"
        foreach ($c in @($k.constraints)) { Add "    - $(Format-Cell $c)" }
    }
}

$ctx = $report.context
$unknown = if (@($ctx.unknown).Count) { " Unknown: $((@($ctx.unknown)) -join ', ')." } else { '' }
Add
function Format-List($Values) { $v = @($Values | Where-Object { $_ }); if ($v.Count) { $v -join ', ' } else { 'unknown' } }
Add "_Context: BC version $($ctx.'bc-version'); countries $(Format-List $ctx.countries); application areas $(Format-List $ctx.'application-area').$unknown Produced by BCQuality ``$($report.skill.id)`` v$($report.skill.version). The design is input to implementation, not proof that the result is correct: review the finished code with al-code-review._"

$markdown = ($lines -join "`n") + "`n"
if ($OutputPath) {
    Set-Content -LiteralPath $OutputPath -Value $markdown -Encoding utf8 -NoNewline
    Write-Host "Feature design written to $OutputPath"
} else {
    $markdown
}
