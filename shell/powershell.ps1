# Termim PowerShell Integration
# Version 1.0.1
# Source from $PROFILE: . "$HOME\.termim\shell\powershell.ps1"

# Find the termim binary
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

# Helper to find the project root from registry
function Global:Get-TermimProjectRoot {
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

# Background logging with runspaces
$Global:TermimLogger = [powershell]::Create()
$Global:TermimLogger.Runspace = [runspacefactory]::CreateRunspace()
$Global:TermimLogger.Runspace.Open()

function Global:Invoke-TermimLogAsync {
    param([string]$command)
    if (-not $Global:TermimBin) { return }
    
    # Run logging in a separate thread to avoid blocking
    try {
        $sb = [scriptblock]::Create("& '$Global:TermimBin' log '$($command.Replace("'", "''"))' 2>&1 | Out-Null")
        $Global:TermimLogger.Commands.Clear()
        $Global:TermimLogger.AddScript($sb)
        $Global:TermimLogger.BeginInvoke() | Out-Null
    } catch {
        # Silent failure for background logging
    }
}

# PSReadLine custom key handlers
if (Get-Module PSReadLine) {
    $Global:TermimIdx = 0
    $Global:TermimOriginalInput = ""
    $Global:TermimCache = @()

    # Navigate project history with Up arrow
    Set-PSReadLineKeyHandler -Key UpArrow -ScriptBlock {
        param($key, $arg)
        if (-not $Global:TermimBin) { [Microsoft.PowerShell.PSConsoleReadLine]::PreviousHistory($key, $arg); return }

        $currentLine = ""
        try { $currentLine = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
        catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $currentLine = $l }

        # Fetch and cache project history on first press
        if ($Global:TermimIdx -eq 0) {
            $Global:TermimOriginalInput = $currentLine
            $root = Get-TermimProjectRoot
            if ($root) {
                $Global:TermimCache = & $Global:TermimBin query 2>$null | Select-Object -Unique
            }
        }

        if ($Global:TermimCache.Length -gt 0) {
            if ($Global:TermimIdx -lt $Global:TermimCache.Length) {
                $cmd = $Global:TermimCache[$Global:TermimIdx]
                if ($cmd -ne $currentLine) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $cmd)
                }
                $Global:TermimIdx++
            }
        }
    }

    # Navigate project history with Down arrow
    Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
        param($key, $arg)
        if ($Global:TermimIdx -le 0) { return }

        $currentLine = ""
        try { $currentLine = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
        catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $currentLine = $l }

        $Global:TermimIdx--
        if ($Global:TermimIdx -eq 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $Global:TermimOriginalInput)
        } else {
            $cmd = $Global:TermimCache[$Global:TermimIdx - 1]
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $cmd)
        }
    }

    # Log command on Enter
    Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
        $line = ""
        try { $line = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
        catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $line = $l }

        if ($line.Trim()) {
            if (Get-Command Invoke-TermimLogAsync -ErrorAction SilentlyContinue) {
                Invoke-TermimLogAsync -command $line
            }
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    # Search project history with fzf
    Set-PSReadLineKeyHandler -Key "Ctrl+p" -ScriptBlock {
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
                    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($selected)
                    $curr = ""
                    try { $curr = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
                    catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $curr = $l }
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $curr.Length, $selected)
                    $Global:TermimIdx = 0 
                }
            }
        }
    }
}

# Reset state for every new prompt
function prompt {
    $Global:TermimIdx = 0
    $Global:TermimCache = @()
    
    # Generic prompt output
    "PS $(Get-Location)> "
}
