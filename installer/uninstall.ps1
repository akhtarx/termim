# Termim Uninstaller for Windows
Write-Host "=== Termim Uninstaller ===" -ForegroundColor Cyan

# 1. Stop the daemon
Write-Host "[1/4] Stopping Termim daemon..." -ForegroundColor Yellow
$process = Get-Process -Name termimd -ErrorAction SilentlyContinue
if ($process) {
    Stop-Process -Name termimd -Force
    Write-Host "  OK: Stopped" -ForegroundColor Green
}
else {
    Write-Host "  OK: Daemon not running" -ForegroundColor Gray
}

# 2. Remove from PowerShell Profile
Write-Host "[2/4] Removing integration from $PROFILE..." -ForegroundColor Yellow
if (Test-Path $PROFILE) {
    $content = Get-Content $PROFILE
    $newContent = $content | Where-Object { $_ -notmatch "[\/\\]\.termim[\/\\]shell[\/\\]powershell\.ps1" }
    $newContent | Set-Content $PROFILE
    Write-Host "  OK: Profile cleaned" -ForegroundColor Green
}

# 3. Remove .termim directory
Write-Host "[3/4] Removing files from $HOME\.termim..." -ForegroundColor Yellow
$termimDir = "$HOME\.termim"
if (Test-Path $termimDir) {
    Remove-Item -Recurse -Force $termimDir
    Write-Host "  OK: Directory removed" -ForegroundColor Green
}

# 4. Remove from PATH (User Environment)
Write-Host "[4/4] Removing from PATH..." -ForegroundColor Yellow
$path = [Environment]::GetEnvironmentVariable("PATH", "User")
$termimBin = "$HOME\.termim\bin"
if ($path -like "*$termimBin*") {
    $newPath = ($path -split ';' | Where-Object { $_ -ne $termimBin }) -join ';'
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "  OK: PATH cleaned" -ForegroundColor Green
}

Write-Host "`nTermim has been completely uninstalled." -ForegroundColor Cyan
Write-Host "Please restart your terminal to apply all changes." -ForegroundColor Gray
