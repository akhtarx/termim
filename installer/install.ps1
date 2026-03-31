# Termim Windows Installer (PowerShell)
# Usage: .\installer\install.ps1

$ErrorActionPreference = "Stop"

$termimDir = Join-Path $HOME ".termim"
$binDir = Join-Path $termimDir "bin"

Write-Host "=== Termim Windows Installer (Pure CLI) ===" -ForegroundColor Cyan
Write-Host ""

# 1. Build release binary
Write-Host "[1/4] Building Termim (release)..." -ForegroundColor Yellow
cargo build --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Build failed. Please check the errors above." -ForegroundColor Red
    exit 1
}
Write-Host "  OK: Built" -ForegroundColor Green

# 2. Create directory structure
Write-Host "[2/4] Creating $termimDir..." -ForegroundColor Yellow
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}
Write-Host "  OK: Created" -ForegroundColor Green

# 3. Install binary
Write-Host "[3/4] Installing binary..." -ForegroundColor Yellow
Copy-Item "target\release\termim.exe" "$binDir\termim.exe" -Force
Write-Host "  OK: Installed to $binDir" -ForegroundColor Green

# 4. Update PATH
Write-Host "[4/4] Configuring PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$binDir*") {
    $newPath = "$currentPath;$binDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  OK: $binDir added to User PATH" -ForegroundColor Green
}
else {
    Write-Host "  OK: $binDir already in PATH" -ForegroundColor Green
}

# 5. PowerShell Integration
Write-Host "[5/5] Configuring PowerShell Integration..." -ForegroundColor Yellow
$shellDir = Join-Path $termimDir "shell"
if (-not (Test-Path $shellDir)) { New-Item -ItemType Directory -Path $shellDir -Force | Out-Null }
$targetShellScript = Join-Path $shellDir "powershell.ps1"
Remove-Item $targetShellScript -ErrorAction SilentlyContinue
Copy-Item "shell\powershell.ps1" $targetShellScript -Force
Write-Host "  OK: Integration script updated at $targetShellScript" -ForegroundColor Green

$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) {
    $null = New-Item -Path $profilePath -ItemType File -Force
}

$sourceCmd = ". '$targetShellScript'"
$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue
if ($profileContent -notcontains $sourceCmd) {
    Set-Content -Path $profilePath -Value $profileContent
    Add-Content -Path $profilePath -Value "`n$sourceCmd"
    Write-Host "  OK: Added integration to your PowerShell Profile" -ForegroundColor Green
}
else {
    Write-Host "  OK: Integration already in Profile" -ForegroundColor Green
}

# --- Instant Activation for Current Session ---
Write-Host ""
Write-Host "Activating for current session..." -ForegroundColor Yellow
$env:Path += ";$binDir"
if (Test-Path $targetShellScript) {
    . $targetShellScript
}
Write-Host "  OK: Session PATH updated" -ForegroundColor Green
Write-Host "  OK: Integration script sourced" -ForegroundColor Green

Write-Host ""
Write-Host "=== Termim installed and ACTIVATED successfully! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can use it right now in this terminal window."
Write-Host "Try pressing 'Up Arrow' or 'Ctrl+P'!"
Write-Host ""
Write-Host "Note: Binary is at $binDir\termim.exe" -ForegroundColor Gray
