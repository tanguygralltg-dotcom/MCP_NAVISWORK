<#
.SYNOPSIS
  Builds a self-contained interactive HTML clash report from the Navisworks MCP clash register.
.PARAMETER Rows      rows.json   (one object per clash result, produced by build-groups.ps1)
.PARAMETER Groups    groups.json (one object per clash group: test, name, level, grid, depthMm, rep, results)
.PARAMETER Template  clash-report-template.html (contains the /*__DATA__*/null placeholder)
.PARAMETER ImageDir  folder with <resultGuid>.png snapshots (optional; embedded as base64)
.PARAMETER Out       output .html path
#>
param(
  [Parameter(Mandatory)][string]$Rows,
  [Parameter(Mandatory)][string]$Groups,
  [Parameter(Mandatory)][string]$Template,
  [string]$ImageDir,
  [Parameter(Mandatory)][string]$Out,
  [string]$Project = 'Parking PRK',
  [string]$Document = 'Test navis work.nwf',
  [hashtable]$Tolerances = @{}
)
$ErrorActionPreference = 'Stop'
# Note: PowerShell variables are case-insensitive, so the data must not reuse the [string] parameter names.
# (PowerShell 5: piping a JSON array into ConvertFrom-Json yields ONE array object; call it directly instead.)
$rowData   = ConvertFrom-Json (Get-Content $Rows   -Raw -Encoding UTF8)
$groupData = ConvertFrom-Json (Get-Content $Groups -Raw -Encoding UTF8)

$levelOrder = @('S2','S1','N0','N1','N2','N3','N4','N5','N6','TT','Sans niveau')
$tests = foreach ($t in ($rowData | Group-Object test | Sort-Object Name)) {
  $n = $t.Name
  $m = [regex]::Match($n, '^(?:\d+\s+)?(?:DEGAGEMENT\s+)?(\w+)\s+vs\s+(\w+)', 'IgnoreCase')
  $type = if ($n -match 'DEGAGEMENT') { 'Clearance' } else { 'Hard' }
  $tol = if ($Tolerances.ContainsKey($n)) { $Tolerances[$n] } elseif ($type -eq 'Clearance') { 50 } else { 10 }
  [ordered]@{ id = $n; name = $n; a = $m.Groups[1].Value.ToUpper(); b = $m.Groups[2].Value.ToUpper(); type = $type; tolMm = $tol }
}
$results = foreach ($r in $rowData) {
  [ordered]@{
    id = $r.guid; test = $r.test; name = $r.name; status = $r.status; distMm = [double]$r.distMm
    level = $r.level; grid = $r.grid; assignee = ''; priority = 0
    a = [ordered]@{ name = $(if ($r.aCat) { $r.aCat } else { $r.aName }); type = "$($r.aName) · $($r.aModel -replace '^\d{4}-\d{2}-\d{2}_','')" }
    b = [ordered]@{ name = $(if ($r.bCat) { $r.bCat } else { $r.bName }); type = "$($r.bName)$(if ($r.bElemId) { " #$($r.bElemId)" }) · $($r.bModel -replace '^\d{4}-\d{2}-\d{2}_','')" }
  }
}
$i = 0
$grp = foreach ($g in $groupData) {
  $i++
  $img = $null
  if ($ImageDir) {
    $p = Join-Path $ImageDir "$($g.rep).png"
    if (Test-Path $p) { $img = 'data:image/png;base64,' + [Convert]::ToBase64String([IO.File]::ReadAllBytes($p)) }
  }
  [ordered]@{ id = "g$i"; test = $g.test; name = $g.name; level = $g.level; grid = $g.grid; depthMm = [double]$g.depthMm; results = @($g.results); img = $img }
}
$data = [ordered]@{
  reportId = (Get-Date -Format 'yyyyMMdd-HHmm'); project = $Project; document = $Document
  generated = (Get-Date -Format 'dd/MM/yyyy HH:mm'); levelOrder = $levelOrder
  tests = @($tests); results = @($results); groups = @($grp)
}
$json = $data | ConvertTo-Json -Depth 6 -Compress
$json = $json.Replace('</', '<\/')   # never close the <script> early
$html = (Get-Content $Template -Raw -Encoding UTF8).Replace('/*__DATA__*/null', $json)
[IO.File]::WriteAllText($Out, $html, (New-Object Text.UTF8Encoding($false)))
"OK  $Out  ($([math]::Round((Get-Item $Out).Length/1KB)) KB, $(@($results).Count) conflits, $(@($grp).Count) groupes, $(@($grp | Where-Object { $_.img }).Count) images)"
