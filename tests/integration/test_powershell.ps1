$ErrorActionPreference = 'Stop'

Write-Host "Running PowerShell integration test..."

# Setup clean environment
$tempHome = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempHome -Force | Out-Null
$env:HOME = $tempHome

$binPath = if ($env:TERMIM_BIN) { $env:TERMIM_BIN } else { "termim" }
$hookPath = Resolve-Path "shell\powershell.ps1"
Set-Location $tempHome

# Load module
. $hookPath

# Override paths
$Global:TermimBin = $binPath
$Global:TermimHome = "$tempHome\.termim"
New-Item -ItemType Directory -Path $Global:TermimHome -Force | Out-Null

Write-Host "Log command 1..."
$Global:TermimPreExecDir = (Get-Location).Path
& $Global:TermimBin log "Write-Host hello_world" --prev "none" --exit 0 --cwd $Global:TermimPreExecDir --pre-exec 2>>"$Global:TermimHome\termim.log"
& $Global:TermimBin log "Write-Host hello_world" --prev "none" --exit 0 --cwd $Global:TermimPreExecDir --post-exec 2>>"$Global:TermimHome\termim.log"

# wait a moment for the background process to log
Start-Sleep -Seconds 1

Write-Host "Test History Query (Up Arrow simulation)..."
$Global:TermimCache = @(& $Global:TermimBin query --history-only --prev "none" --cwd "$Global:TermimPreExecDir" 2>$null | Select-Object -Unique)

if ($Global:TermimCache.Count -eq 0 -or $Global:TermimCache[0] -ne "Write-Host hello_world") {
    Write-Host "FAIL: Expected cache[0] to be 'Write-Host hello_world', got '$($Global:TermimCache[0])'"
    exit 1
}

Write-Host "PASS: PowerShell integration successful."
