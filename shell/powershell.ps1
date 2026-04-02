# Termim Professional Shell Integration (v1.0.0)
# Mastery Edition: Global Gold Standard (Resilient & Silky Smooth)
# Source from $PROFILE: . "$HOME\.termim\shell\powershell.ps1"

# --- 1. Universal Path Strategy & Fallback ---

$Global:TermimBin = ""
$userHome = [System.Environment]::GetFolderPath("UserProfile")
$possiblePaths = @(
    "$HOME\.termim\bin\termim.exe", 
    "$userHome\.termim\bin\termim.exe",
    "C:\Users\$($env:USERNAME)\.termim\bin\termim.exe"
)

foreach ($p in $possiblePaths) {
    if (Test-Path $p) {
        $Global:TermimBin = $p
        $binDir = [System.IO.Path]::GetDirectoryName($p)
        if ($env:PATH -notlike "*$binDir*") { $env:PATH = "$binDir;$env:PATH" }
        break
    }
}

function Invoke-Termim {
    param([string]$cmd, [string]$args_str)
    if ($Global:TermimBin) {
        try {
            # Execute with speed and silence
            & $Global:TermimBin $cmd $args_str 2>$null
        } catch { return $null }
    }
    return $null
}

# --- 2. Core Logic & Registry ---

$Global:TermimIdx = 0
$Global:TermimOriginalInput = ""
$Global:TermimCache = @()

function Get-TermimProjectRoot {
    $current = (Get-Location).Path
    $registry = "$HOME\.termim\registry.txt"
    if (-not (Test-Path $registry)) { return $null }
    
    $roots = Get-Content $registry -ErrorAction SilentlyContinue
    if (-not $roots) { return $null }
    foreach ($root in $roots) {
        if ($current.StartsWith($root, "OrdinalIgnoreCase")) {
            return $root
        }
    }
    return $null
}

# --- 3. PSReadLine Key Handlers (Gold Standard Mastery) ---

if (Get-Module PSReadLine) {
    # Up-Arrow Handler
    Set-PSReadLineKeyHandler -Key UpArrow -ScriptBlock {
        param($key, $arg)
        
        # 1. Initialize Cache on First Press
        if ($Global:TermimIdx -eq 0) {
            $Global:TermimOriginalInput = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content
            $root = Get-TermimProjectRoot
            if ($root -and $Global:TermimBin) {
                $Global:TermimCache = & $Global:TermimBin query 2>$null | Select-Object -Unique
            }
        }

        # 2. Hard-Lock at boundaries (Industrial Stability)
        if ($Global:TermimCache.Length -eq 0) {
            return
        }

        # 3. Stateful Navigation (Silky Smooth)
        if ($Global:TermimIdx -lt $Global:TermimCache.Length) {
            $nextIdx = $Global:TermimIdx + 1
            $cmd = $Global:TermimCache[-($nextIdx)]
            $line = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content
            
            # Anti-Flicker: Only update if different
            if ($cmd -ne $line) {
                $Global:TermimIdx = $nextIdx
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $cmd)
            } else {
                $Global:TermimIdx = $nextIdx
            }
        }
    }

    # Down-Arrow Handler
    Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
        param($key, $arg)
        if ($Global:TermimIdx -le 0) {
            return
        }

        $nextIdx = $Global:TermimIdx - 1
        $line = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content
        
        if ($nextIdx -eq 0) {
            if ($line -ne $Global:TermimOriginalInput) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $Global:TermimOriginalInput)
            }
            $Global:TermimIdx = 0
        } else {
            $cmd = $Global:TermimCache[-($nextIdx)]
            if ($cmd -ne $line) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $cmd)
                $Global:TermimIdx = $nextIdx
            } else {
                $Global:TermimIdx = $nextIdx
            }
        }
    }
}

# --- 4. Ctrl+P: Interactive Palette ---

function Invoke-TermimPalette {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "`n[termim] install 'fzf' for the palette." -ForegroundColor Yellow
        return
    }

    if ($Global:TermimBin) {
        $history = & $Global:TermimBin query 2>$null | Select-Object -Unique
        if ($history.Length -gt 0) {
            $reversed = [array]$history
            [Array]::Reverse($reversed)
            $selected = $reversed | fzf --height 40% --reverse --border rounded --prompt "  termim > " --header "Project History" --no-sort
            if ($selected) {
                [Microsoft.PowerShell.PSConsoleReadLine]::AddHistory($selected)
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content.Length, $selected)
                $Global:TermimIdx = 0 
                $Global:TermimCache = @()
            }
        }
    }
}

if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Key "Ctrl+p" -ScriptBlock {
        Invoke-TermimPalette
    }
}

# --- 5. Command Hook & Reset ---

function prompt {
    $Global:TermimIdx = 0
    "PS $(Get-Location)> "
}
