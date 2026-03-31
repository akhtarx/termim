# Termim PowerShell Integration (Smart Hybrid Mode)
# Source from $PROFILE:  . ~/.termim/shell/powershell.ps1

$termimDir = "$HOME\.termim"
$binDir = Join-Path $termimDir "bin"
$projectsDir = Join-Path $termimDir "projects"
$registryFile = Join-Path $termimDir "registry.txt"

# 1. Add to PATH for this session
if ($env:Path -notlike "*$binDir*") {
    $env:Path = "$binDir;$env:Path"
}

# 2. Native Project Detection Logic (Zero Lag)
function Get-TermimProjectRoot {
    param($Path)
    $markers = @(".git", "package.json", "Cargo.toml", "go.mod", "pyproject.toml", "Makefile", "docker-compose.yml")
    $current = $Path
    while ($current -and (Test-Path $current)) {
        foreach ($m in $markers) {
            if (Test-Path (Join-Path $current $m)) { return $current }
        }
        $parent = Split-Path $current -Parent
        if ($parent -eq $current -or !$parent) { break }
        $current = $parent
    }
    
    # 3. Check Global Registry (Zero-Pollution manual projects)
    if (Test-Path $registryFile) {
        $registry = Get-Content $registryFile -ErrorAction SilentlyContinue
        foreach ($p in $registry) {
            if ($Path.StartsWith($p)) { return $p }
        }
    }
    
    return $null
}

function Get-TermimHash {
    param($PathStr)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PathStr.ToLower()))
    return ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
}

# 4. State Management
if ($null -eq $global:TermimNativeHistPath) {
    if (Get-Module PSReadLine) {
        $global:TermimNativeHistPath = (Get-PSReadLineOption).HistorySavePath
    }
}
$global:TermimLastHash = ""

# 5. Instant Smart Context Swapping
if ($null -eq $global:__TermimHooked) {
    $global:__TermimHooked = $true
    
    if ($null -eq (Get-Command -Name "TermimOriginalPrompt" -ErrorAction SilentlyContinue)) {
        $origPrompt = Get-Content -Path "function:prompt" -ErrorAction SilentlyContinue
        if ($null -ne $origPrompt) {
            Set-Item -Path "function:TermimOriginalPrompt" -Value ([scriptblock]::Create($origPrompt)) -ErrorAction SilentlyContinue
        }
    }

    function prompt {
        # 1. Smart Detection
        $root = Get-TermimProjectRoot $PWD.Path
        
        if ($null -ne $root) {
            # MODE: Project-Aware History
            $hash = Get-TermimHash $root
            if ($hash -ne $global:TermimLastHash) {
                $global:TermimLastHash = $hash
                $histFile = Join-Path $projectsDir "$hash.txt"
                if (!(Test-Path $projectsDir)) { New-Item $projectsDir -ItemType Directory | Out-Null }
                if (!(Test-Path $histFile)) { New-Item $histFile -ItemType File | Out-Null }
                
                # Point to Project history (Native Speed)
                if (Get-Module PSReadLine) {
                    try {
                        Set-PSReadLineOption -HistorySavePath $histFile
                        [Microsoft.PowerShell.PSConsoleReadLine]::ReadHistoryFile($histFile)
                    } catch {}
                }
            }
        } else {
            # MODE: Global Native History (Clean & Silent)
            if ($global:TermimLastHash -ne "") {
                $global:TermimLastHash = ""
                if (Get-Module PSReadLine -and $null -ne $global:TermimNativeHistPath) {
                    try {
                        Set-PSReadLineOption -HistorySavePath $global:TermimNativeHistPath
                        [Microsoft.PowerShell.PSConsoleReadLine]::ReadHistoryFile($global:TermimNativeHistPath)
                    } catch {}
                }
            }
        }

        # 2. Call Original Prompt
        if (Get-Command -Name "TermimOriginalPrompt" -ErrorAction SilentlyContinue) { return TermimOriginalPrompt }
        return "PS $($ExecutionContext.SessionState.Path.CurrentLocation)> "
    }
}

# 6. Ctrl+P Fuzzy Search Palette (Requires fzf)
if (Get-Command "fzf" -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key "Ctrl+p" -ScriptBlock {
        $cmd = termim query | fzf --height 40% --reverse --header="Termim Project History"
        if ($cmd) {
            [Microsoft.PowerShell.PSConsoleReadLine]::DeleteLine()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($cmd)
        }
    }
}
