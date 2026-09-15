param([string]$Lazarus = 'C:\lazarus')
$ErrorActionPreference = 'Stop'
$auditRoot = $PSScriptRoot
$sourceRoot = Join-Path $auditRoot 'src'
$fpc = Join-Path $Lazarus 'fpc/3.2.2/bin/x86_64-win64/fpc.exe'
Push-Location $sourceRoot
try {
  # Build the captured source snapshot, keeping root project artifacts untouched.
  & (Join-Path $Lazarus 'lazbuild.exe') --build-all project1.lpi *> (Join-Path $auditRoot 'logs/build-gui.txt')
  if ($LASTEXITCODE -ne 0) { throw 'GUI build failed' }
  $coreFlags = @('-B','-O1',"-Fu$sourceRoot","-FU$auditRoot/units","-FE$auditRoot/bin")
  & $fpc @coreFlags test_calc.lpr *> (Join-Path $auditRoot 'logs/build-baseline.txt')
  if ($LASTEXITCODE -ne 0) { throw 'Core baseline build failed' }
  & "$auditRoot/bin/test_calc.exe" *> "$auditRoot/logs/baseline-core.txt"
  $baselineExit = $LASTEXITCODE
  & $fpc @coreFlags "$auditRoot/audit_core.lpr" *> "$auditRoot/logs/build-core.txt"
  if ($LASTEXITCODE -ne 0) { throw 'Audit core build failed' }
  & "$auditRoot/bin/audit_core.exe" *> "$auditRoot/logs/audit-core.txt"
  $coreExit = $LASTEXITCODE
  $guiFlags = @("-Fu$sourceRoot/lib/x86_64-win64","-Fu$sourceRoot",
    "-Fu$Lazarus/lcl/units/x86_64-win64","-Fu$Lazarus/lcl/units/x86_64-win64/win32",
    "-Fu$Lazarus/components/lazutils/lib/x86_64-win64","-Fu$Lazarus/packager/units/x86_64-win64",
    "-FU$auditRoot/units","-FE$auditRoot/bin")
  & $fpc @guiFlags test_gui_calc.lpr *> "$auditRoot/logs/build-gui-test.txt"
  if ($LASTEXITCODE -ne 0) { throw 'GUI baseline build failed' }
  & "$auditRoot/bin/test_gui_calc.exe" *> "$auditRoot/logs/baseline-gui.txt"
  & $fpc @guiFlags "$auditRoot/audit_gui.lpr" *> "$auditRoot/logs/build-audit-gui.txt"
  if ($LASTEXITCODE -ne 0) { throw 'Audit GUI build failed' }
  & "$auditRoot/bin/audit_gui.exe" *> "$auditRoot/logs/audit-gui.txt"
  $guiExit = $LASTEXITCODE
  & "$auditRoot/run-probes.ps1"
  [pscustomobject]@{CoreBaselineExit=$baselineExit;AuditCoreExit=$coreExit;AuditGuiExit=$guiExit} | ConvertTo-Json | Set-Content "$auditRoot/logs/exit-codes.json"
} finally { Pop-Location }
# Expected to fail against the audited snapshot: this suite reproduces defects.
if ($baselineExit -ne 0 -or $coreExit -ne 0 -or $guiExit -ne 0) { exit 1 }
