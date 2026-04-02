# Termim Professional Shell Integration (v1.0.0)
# Mastery Edition: Stateful Native Navigation (Cache-Enabled)
# Source from $PROFILE: . "$HOME\.termim\shell\powershell.ps1"

# --- 1. Core Logic & Registry ---

$Global:TermimIdx = 0
$Global:TermimOriginalInput = ""
$Global:TermimCache = @()

function Get-TermimProjectRoot {
    $current = (Get-Location).Path
    $registry = "$HOME\.termim\registry.txt"
    if (-not (Test-Path $registry)) { return $null }
    
    $roots = Get-Content $registry
    foreach ($root in $roots) {
        if ($current.StartsWith($root, "OrdinalIgnoreCase")) {
            return $root
        }
    }
    return $null
}

function Get-TermimHash($path) {
    if (-not $path) { return "global" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($path.ToLower())
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    return [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
}

# --- 2. History Fetcher ---

function Get-TermimProjectHistory {
    $root = Get-TermimProjectRoot
    if ($root) {
        $hash = Get-TermimHash $root
        $path = "$HOME\.termim\projects\$hash.txt"
        if (Test-Path $path) {
            # Unique history (reversed for easy indexing)
            return Get-Content $path | Select-Object -Unique
        }
    }
    return @()
}

# --- 3. PSReadLine Key Handlers (Cache Mastery) ---

if (Get-Module PSReadLine) {
    # Up-Arrow Handler
    Set-PSReadLineKeyHandler -Key UpArrow -ScriptBlock {
        param($key, $arg)
        
        # Initialize Cache on First Press (Industrial Latency Fix)
        if ($Global:TermimIdx -eq 0) {
            $Global:TermimOriginalInput = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content
            $Global:TermimCache = Get-TermimProjectHistory
        }

        if ($Global:TermimCache.Length -eq 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::UpArrow($key, $arg)
            return
        }

        if ($Global:TermimIdx -lt $Global:TermimCache.Length) {
            $Global:TermimIdx++
            # Access In-Memory Array for 0ms recall
            $cmd = $Global:TermimCache[-($Global:TermimIdx)]
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content.Length, $cmd)
        }
    }

    # Down-Arrow Handler
    Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
        param($key, $arg)
        if ($Global:TermimIdx -le 0 -or $Global:TermimCache.Length -eq 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::DownArrow($key, $arg)
            return
        }

        $Global:TermimIdx--
        if ($Global:TermimIdx -eq 0) {
            # Restore original from memory
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content.Length, $Global:TermimOriginalInput)
        } else {
            # Access In-Memory Array for 0ms recall
            $cmd = $Global:TermimCache[-($Global:TermimIdx)]
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content.Length, $cmd)
        }
    }
}

# --- 4. Ctrl+P: Interactive Palette ---

function Invoke-TermimPalette {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Host "`n[termim] install 'fzf' to use the Ctrl+P palette." -ForegroundColor Yellow
        return
    }

    $history = Get-TermimProjectHistory
    if ($history.Length -gt 0) {
        $reversed = [array]$history
        [Array]::Reverse($reversed)
        $selected = $reversed | fzf --height 40% --reverse --border rounded --prompt "  termim > " --header "Project History" --no-sort
        if ($selected) {
            [Microsoft.PowerShell.PSConsoleReadLine]::AddHistory($selected)
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content.Length, $selected)
            $Global:TermimIdx = 0 
            $Global:TermimCache = @() # Clear cache on palette exit
        }
    }
}

if (Get-Module PSReadLine) {
    Set-PSReadLineKeyHandler -Key "Ctrl+p" -ScriptBlock {
        Invoke-TermimPalette
    }
}

# --- 5. Command Hook & Cache Purge ---

function prompt {
    $Global:TermimIdx = 0
    $Global:TermimCache = @() # Purge navigation cache on every command
    "PS $(Get-Location)> "
}
