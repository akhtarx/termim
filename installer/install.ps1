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
Write-Host "[4/6] Configuring PATH..." -ForegroundColor Yellow
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newBinDir = $binDir
if ($currentPath -notlike "*$newBinDir*") {
    $newPath = "$currentPath;$newBinDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  OK: $newBinDir added to User PATH" -ForegroundColor Green
}
else {
    Write-Host "  OK: $newBinDir already in PATH" -ForegroundColor Green
}

# 5. PowerShell Integration
Write-Host "[5/6] Configuring PowerShell Integration..." -ForegroundColor Yellow
$shellDir = Join-Path $termimDir "shell"
if (-not (Test-Path $shellDir)) { New-Item -ItemType Directory -Path $shellDir -Force | Out-Null }

$targetPsScript = Join-Path $shellDir "powershell.ps1"
Copy-Item "shell\powershell.ps1" $targetPsScript -Force
Write-Host "  OK: PowerShell script updated at $targetPsScript" -ForegroundColor Green

$profilePath = $PROFILE.CurrentUserAllHosts
if (-not (Test-Path $profilePath)) { $null = New-Item -Path $profilePath -ItemType File -Force }
$sourcePsCmd = ". '$targetPsScript'"
$profileContent = Get-Content $profilePath -ErrorAction SilentlyContinue
if ($profileContent -notcontains $sourcePsCmd) {
    Add-Content -Path $profilePath -Value "`n$sourcePsCmd"
    Write-Host "  OK: Added integration to your PowerShell Profile" -ForegroundColor Green
} else {
    Write-Host "  OK: Integration already in PowerShell Profile" -ForegroundColor Green
}

# 6. Git Bash Integration (Optional Detect)
Write-Host "[6/6] Detecting Git Bash for Windows..." -ForegroundColor Yellow
$homeDir = [System.Environment]::GetFolderPath("UserProfile")
$bashrc = Join-Path $homeDir ".bashrc"
$targetBashScript = Join-Path $shellDir "bash.sh"

# Use forward slashes for Bash compatibility
$unixTargetBashPath = "~/.termim/shell/bash.sh"
$sourceBashCmd = "source $unixTargetBashPath"

Copy-Item "shell\bash.sh" $targetBashScript -Force
Write-Host "  OK: Bash script updated at $targetBashScript" -ForegroundColor Green

# 6. Git Bash Integration (Aggressive Detect)
Write-Host "[6/6] Detecting Git Bash for Windows..." -ForegroundColor Yellow
$homeDir = [System.Environment]::GetFolderPath("UserProfile")

# Priority list for Git Bash config files
$bashConfigs = @(".bashrc", ".bash_profile", ".profile")
$bashConfigUsed = $null

foreach ($config in $bashConfigs) {
    if (Test-Path (Join-Path $homeDir $config)) {
        $bashConfigUsed = Join-Path $homeDir $config
        break
    }
}

$targetBashScript = Join-Path $shellDir "bash.sh"
$unixTargetBashPath = "~/.termim/shell/bash.sh"
$sourceBashCmd = "source $unixTargetBashPath"

Copy-Item "shell\bash.sh" $targetBashScript -Force
Write-Host "  OK: Bash script updated at $targetBashScript" -ForegroundColor Green

if ($null -eq $bashConfigUsed) {
    $bashConfigUsed = Join-Path $homeDir ".bash_profile"
    New-Item -Path $bashConfigUsed -ItemType File -Force | Out-Null
    Write-Host "  OK: Created new Git Bash profile at $bashConfigUsed" -ForegroundColor Green
}

$bashContent = Get-Content $bashConfigUsed -ErrorAction SilentlyContinue
if ($bashContent -notcontains $sourceBashCmd) {
    Add-Content -Path $bashConfigUsed -Value "`n# Termim Mastery Integration`n$sourceBashCmd"
    Write-Host "  OK: Added integration to $bashConfigUsed" -ForegroundColor Green
} else {
    Write-Host "  OK: Integration already in $bashConfigUsed" -ForegroundColor Green
}

# --- Instant Activation for Current Session (PowerShell) ---
Write-Host ""
Write-Host "Activating for current session..." -ForegroundColor Yellow
$env:Path += ";$binDir"
if (Test-Path $targetPsScript) { . $targetPsScript }
Write-Host "  OK: Session PATH updated" -ForegroundColor Green
Write-Host "  OK: PowerShell integration sourced" -ForegroundColor Green

Write-Host ""
Write-Host "=== Termim v1.0.0 Universal Installation Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "PowerShell: Ready! Try 'Up Arrow' or 'Ctrl+P'."
Write-Host "Git Bash  : Restart your Git Bash or run 'source ~/.bashrc' to activate."
Write-Host ""
Write-Host "Note: Binary is at $binDir\termim.exe" -ForegroundColor Gray
