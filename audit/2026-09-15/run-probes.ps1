$ErrorActionPreference = 'Stop'
$auditDir = $PSScriptRoot
$probeExe = Join-Path $auditDir 'bin/audit_core.exe'
$records = @()
foreach ($probeArgs in @('sin-billion','sin-trillion','sin-huge','comb-huge','expr-bench 100','expr-bench 1000','expr-bench 5000')) {
    $logName = $probeArgs.Replace(' ','-')
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $probeProcess = Start-Process -FilePath $probeExe -ArgumentList $probeArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $auditDir "logs/$logName.txt") -RedirectStandardError (Join-Path $auditDir "logs/$logName.err.txt")
    $timeoutMs = if ($probeArgs -eq 'expr-bench 1000') { 5000 } else { 3000 }
    $completed = $probeProcess.WaitForExit($timeoutMs)
    $cpu = $probeProcess.TotalProcessorTime.TotalMilliseconds
    if (-not $completed) { $probeProcess.Kill(); $probeProcess.WaitForExit() }
    $watch.Stop()
    $records += [pscustomobject]@{Probe=$probeArgs;TimeoutMs=$timeoutMs;Completed=$completed;ExitCode=$probeProcess.ExitCode;ElapsedMs=$watch.ElapsedMilliseconds;CpuMs=$cpu;Output=(Get-Content (Join-Path $auditDir "logs/$logName.txt") -Raw)}
    $probeProcess.Dispose()
}
$records | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $auditDir 'logs/probes.json')
$records | Format-Table -AutoSize
