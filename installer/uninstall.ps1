# Termim Windows Uninstaller (Universal: PowerShell + Git Bash)
# Usage: .\installer\uninstall.ps1

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== Termim Windows Uninstaller (Industry-Grade) ===" -ForegroundColor Cyan
Write-Host ""

$termimDir = Join-Path $HOME ".termim"
$binDir = Join-Path $termimDir "bin"

# 1. PowerShell Profile Cleanup
Write-Host "[1/4] Cleaning PowerShell Integration..." -ForegroundColor Yellow
$profilePath = $PROFILE.CurrentUserAllHosts
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath
    $newContent = $content | Where-Object { $_ -notlike "*\.termim\shell\powershell.ps1*" }
    Set-Content -Path $profilePath -Value $newContent
    Write-Host "  OK: PowerShell Profile cleaned" -ForegroundColor Green
}

# 2. Git Bash Cleanup
Write-Host "[2/4] Cleaning Git Bash Integration..." -ForegroundColor Yellow
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
foreach ($config in @(".bashrc", ".bash_profile", ".profile")) {
    $path = Join-Path $homeDir $config
    if (Test-Path $path) {
        $content = Get-Content $path
        $newContent = $content | Where-Object { $_ -notlike "*source ~/.termim/shell/bash.sh*" }
        Set-Content -Path $path -Value $newContent
        Write-Host "  OK: $config cleaned" -ForegroundColor Green
    }
}

# 3. PATH Sanitization
Write-Host "[3/4] Removing from PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -like "*$binDir*") {
    $pathArray = $currentPath -split ";"
    $newPath = ($pathArray | Where-Object { $_ -ne $binDir }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  OK: PATH sanitized" -ForegroundColor Green
}

# 4. Final Purge
Write-Host "[4/4] Deleting $termimDir..." -ForegroundColor Yellow
if (Test-Path $termimDir) {
    Remove-Item -Path $termimDir -Recurse -Force
    Write-Host "  OK: $termimDir deleted" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Termim v1.0.0 successfully removed from this machine! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: You can close this terminal window to finalize the changes."
