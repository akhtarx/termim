# Termim Windows Installer (PowerShell)
# Usage: iex (iwr -useb https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.ps1)
#
# Principles:
# 1. Prefer prebuilt binaries.
# 2. Build from source only if -Build flag is passed.
# 3. Idempotent profile configuration.

param(
    [switch]$Build,
    [string]$Version = "latest"
)

$ErrorActionPreference = "Stop"

# --- Configuration ---
$termimDir = Join-Path $HOME ".termim"
$binDir = Join-Path $termimDir "bin"
$shellDir = Join-Path $termimDir "shell"
$repo = "akhtarx/termim"

Write-Host "`n=== Termim: Directory & Context-Aware History Installer ===" -ForegroundColor Cyan

# 1. Prerequisites
Write-Host "[info] Verifying environment..."
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
if (-not (Test-Path $shellDir)) { New-Item -ItemType Directory -Path $shellDir -Force | Out-Null }

# 2. Acquire Binary
$targetExe = Join-Path $binDir "termim.exe"

if ($Build) {
    Write-Host "[info] Building from source as requested..." -ForegroundColor Gray
    if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
        Write-Host "[error] Cargo/Rust not found. Install Rust or run without -Build." -ForegroundColor Red
        exit 1
    }
    cargo build --release
    if ($LASTEXITCODE -eq 0) {
        Copy-Item "target\release\termim.exe" $targetExe -Force
        Write-Host "[success] Built and installed to $targetExe" -ForegroundColor Green
    } else {
        Write-Host "[error] Build failed." -ForegroundColor Red
        exit 1
    }
} else {
    # Automatic download
    $fileName = "termim-windows-x86_64.exe"
    $downloadUrl = if ($Version -eq "latest") { 
        "https://github.com/$repo/releases/latest/download/$fileName" 
    } else { 
        "https://github.com/$repo/releases/download/v$Version/$fileName" 
    }

    Write-Host "[info] Downloading $Version prebuilt binary..."
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $targetExe -UseBasicParsing
        
        # Checksum Verification
        Write-Host "[info] Verifying checksum..." -ForegroundColor Gray
        try {
            $shaUrl = "$downloadUrl.sha256"
            $shaFile = Join-Path $env:TEMP "termim.sha256"
            Invoke-WebRequest -Uri $shaUrl -OutFile $shaFile -UseBasicParsing
            $expected = (Get-Content $shaFile).Split(' ')[0].Trim().ToLower()
            $actual = (Get-FileHash -Path $targetExe -Algorithm SHA256).Hash.ToLower()
            
            if ($expected -eq $actual) {
                Write-Host "[success] Checksum verified." -ForegroundColor Green
            } else {
                Write-Host "[error] Checksum mismatch! Expected: $expected, Actual: $actual" -ForegroundColor Red
                exit 1
            }
            Remove-Item $shaFile -Force
        } catch {
            Write-Host "[warn] No checksum found on server. Skipping verification." -ForegroundColor Yellow
        }

        Write-Host "[success] Termim binary installed to $targetExe" -ForegroundColor Green
    } catch {
        Write-Host "[warn] Download failed. Attempting build from source..." -ForegroundColor Yellow
        if (Get-Command cargo -ErrorAction SilentlyContinue) {
            cargo build --release
            Copy-Item "target\release\termim.exe" $targetExe -Force
            Write-Host "[success] Built from source." -ForegroundColor Green
        } else {
            Write-Host "[error] Prebuilt binary download failed and Cargo is not installed." -ForegroundColor Red
            exit 1
        }
    }
}

# 3. fzf Check
Write-Host "[info] Checking for fzf..."
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Write-Host "[success] fzf found in PATH." -ForegroundColor Green
} elseif (Test-Path (Join-Path $binDir "fzf.exe")) {
    Write-Host "[success] fzf found in Termim bin directory." -ForegroundColor Green
} else {
    Write-Host "[warn] fzf not found. Required for the interactive palette (Ctrl+P)." -ForegroundColor Yellow
    $choice = Read-Host "  Would you like to install a local copy of fzf into $binDir? (y/n)"
    if ($choice -eq 'y') {
        Write-Host "[info] Installing local fzf..."
        $fzfVer = "0.56.0"
        $fzfUrl = "https://github.com/junegunn/fzf/releases/download/v$fzfVer/fzf-$fzfVer-windows_amd64.zip"
        $fzfZip = Join-Path $env:TEMP "fzf.zip"
        
        Invoke-WebRequest -Uri $fzfUrl -OutFile $fzfZip -UseBasicParsing
        Expand-Archive -Path $fzfZip -DestinationPath $env:TEMP -Force
        Move-Item -Path (Join-Path $env:TEMP "fzf.exe") -Destination (Join-Path $binDir "fzf.exe") -Force
        Write-Host "[success] Local fzf installed." -ForegroundColor Green
    }
}

# 4. Install Shell Suites
Write-Host "[info] Installing shell integration scripts..."
if (Test-Path "shell\powershell.ps1") {
    Copy-Item "shell\powershell.ps1" (Join-Path $shellDir "powershell.ps1") -Force
    Copy-Item "shell\bash.sh" (Join-Path $shellDir "bash.sh") -Force
} else {
    Write-Host "[info] Downloading integration scripts..." -ForegroundColor Gray
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$repo/main/shell/powershell.ps1" -OutFile (Join-Path $shellDir "powershell.ps1") -UseBasicParsing
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$repo/main/shell/bash.sh" -OutFile (Join-Path $shellDir "bash.sh") -UseBasicParsing
}

# 5. Idempotent Profile Config
$psScript = Join-Path $shellDir "powershell.ps1"
$initBlock = @"

# >>> termim initialize >>>
if (Test-Path '$psScript') {
    `$env:PATH = '$binDir;' + `$env:PATH
    . '$psScript'
}
# <<< termim initialize <<<
"@

Write-Host "[info] Configuring PowerShell profile..."
if (-not (Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force | Out-Null }
$profileContent = Get-Content $PROFILE -Raw
# Remove existing block
$cleanContent = $profileContent -replace '(?s)# >>> termim initialize >>>.*?# <<< termim initialize <<<', ''
# Append new block
Set-Content -Path $PROFILE -Value ($cleanContent.TrimEnd() + "`n" + $initBlock)
Write-Host "[success] Updated $PROFILE" -ForegroundColor Green

# Instant Activation
Write-Host "[info] Activating for current session..." -ForegroundColor Gray
$env:PATH = "$binDir;" + $env:PATH
if (Test-Path $psScript) { . $psScript }
Write-Host "[success] Session PATH updated and integration sourced." -ForegroundColor Green

Write-Host "`n=== Installation Complete! ===" -ForegroundColor Cyan
Write-Host "Termim is ready! Try 'Up Arrow' or 'Ctrl+P' immediately."
Write-Host ""
