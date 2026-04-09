# Termim Windows Installer (PowerShell)
# Usage: .\installer\install.ps1

$ErrorActionPreference = "Stop"

# Enforce TLS 1.2 for GitHub downloads
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # Fallback to current protocol if setting TLS 1.2 fails
}

$termimDir = Join-Path $HOME ".termim"
$binDir = Join-Path $termimDir "bin"

Write-Host "=== Termim Windows Installer (Pure CLI) ===" -ForegroundColor Cyan
Write-Host ""

# 1. Acquire Binary
Write-Host "[1/4] Acquiring Termim binary..." -ForegroundColor Yellow
$binaryPath = ""

# Mode A: Pre-compiled binary exists in current folder (Release Zip)
if (Test-Path "termim.exe") {
    $binaryPath = "termim.exe"
    Write-Host "  OK: Using local termim.exe" -ForegroundColor Green
}
# Mode B: Build from source if Cargo is available
elseif (Get-Command cargo -ErrorAction SilentlyContinue) {
    Write-Host "  Cargo found. Building from source (release)..." -ForegroundColor Gray
    cargo build --release
    if ($LASTEXITCODE -eq 0) {
        $binaryPath = "target\release\termim.exe"
        Write-Host "  OK: Built successfully" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Build failed. Trying fallback..." -ForegroundColor Yellow
    }
}

# Mode C: Fallback to GitHub Release download
if (-not $binaryPath) {
    Write-Host "  Safe Mode: Downloading latest pre-compiled binary from GitHub..." -ForegroundColor Gray
    $downloadUrl = "https://github.com/akhtarx/termim/releases/latest/download/termim-windows-x86_64.exe"
    $binaryPath = Join-Path $env:TEMP "termim-downloaded.exe"
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $binaryPath -ErrorAction Stop -UseBasicParsing
        Write-Host "  OK: Downloaded latest release" -ForegroundColor Green
    } catch {
        Write-Host "`nERROR: Could not build or download Termim. Please ensure you have an internet connection or Rust installed." -ForegroundColor Red
        exit 1
    }
}

# 2. Create directory structure
Write-Host "[2/4] Creating $termimDir..." -ForegroundColor Yellow
if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}
Write-Host "  OK: Created" -ForegroundColor Green

# 2.5 Install fzf (Dynamic Latest)
Write-Host "[2.5/4] Bundling fzf for history palette..." -ForegroundColor Yellow
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
    $fzfExe = Join-Path $binDir "fzf.exe"
    if (-not (Test-Path $fzfExe)) {
        Write-Host "  fzf not found. Fetching latest version from GitHub..." -ForegroundColor Gray
        try {
            # Use GitHub API to find latest release
            $fzfLatest = Invoke-RestMethod -Uri "https://api.github.com/repos/junegunn/fzf/releases/latest" -UseBasicParsing
            $fzfVersion = $fzfLatest.tag_name.TrimStart('v')
            
            # Detect architecture
            $fzfOS = "windows"
            $fzfArch = if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
            
            Write-Host "  Latest version found: v$fzfVersion ($fzfArch)" -ForegroundColor Gray
            $fzfUrl = "https://github.com/junegunn/fzf/releases/download/v$fzfVersion/fzf-$fzfVersion-$fzfOS`_$fzfArch.zip"
            $fzfZip = Join-Path $env:TEMP "fzf.zip"
            $extractDir = Join-Path $env:TEMP "fzf_extract_$(Get-Random)"
            
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $fzfUrl -OutFile $fzfZip -ErrorAction Stop -UseBasicParsing
            
            if (-not (Test-Path $extractDir)) { New-Item -ItemType Directory -Path $extractDir -Force | Out-Null }
            Expand-Archive -Path $fzfZip -DestinationPath $extractDir -Force
            
            # Find fzf.exe even if it's in a subfolder of the zip
            $extractedExe = Get-ChildItem -Path $extractDir -Filter "fzf.exe" -Recurse | Select-Object -First 1
            if ($extractedExe) {
                Move-Item -Path $extractedExe.FullName -Destination $fzfExe -Force
                Write-Host "  OK: fzf installed to $binDir" -ForegroundColor Green
            } else {
                Write-Host "  WARNING: fzf.exe not found in extracted archive." -ForegroundColor Yellow
            }
            
            # Cleanup
            Remove-Item $fzfZip -Force -ErrorAction SilentlyContinue
            Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "  WARNING: Failed to download fzf ($($_.Exception.Message)). You may need to install it manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  OK: fzf already exists in $binDir" -ForegroundColor Green
    }
} else {
    Write-Host "  OK: fzf already available in PATH" -ForegroundColor Green
}

# 3. Install binary
Write-Host "[3/4] Installing binary..." -ForegroundColor Yellow
Copy-Item $binaryPath "$binDir\termim.exe" -Force
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

# 6. Git Bash Integration
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
    Add-Content -Path $bashConfigUsed -Value "`n# Termim Integration`n$sourceBashCmd"
    Write-Host "  OK: Added integration to $bashConfigUsed" -ForegroundColor Green
} else {
    Write-Host "  OK: Integration already in $bashConfigUsed" -ForegroundColor Green
}

# --- Instant Activation for Current Session ---
Write-Host ""
Write-Host "Activating for current session..." -ForegroundColor Yellow
$env:Path += ";$binDir"
if (Test-Path $targetPsScript) { . $targetPsScript }
Write-Host "  OK: Session PATH updated" -ForegroundColor Green
Write-Host "  OK: PowerShell integration sourced" -ForegroundColor Green

Write-Host ""
Write-Host "=== Termim Universal Installation Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "PowerShell: Ready! Try 'Up Arrow' or 'Ctrl+P'."
Write-Host "Git Bash  : Restart your Git Bash or run 'source ~/.bashrc' to activate."
Write-Host ""
Write-Host "Note: Binary is at $binDir\termim.exe" -ForegroundColor Gray
