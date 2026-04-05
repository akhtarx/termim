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


# Background logging with runspaces
$Global:TermimLogger = [powershell]::Create()
$Global:TermimLogger.Runspace = [runspacefactory]::CreateRunspace()
$Global:TermimLogger.Runspace.Open()

function Global:Invoke-TermimLogAsync {
    param([string]$command, [int]$exitCode = 0, [string]$cwd = "")
    if (-not $Global:TermimBin) { return }
    
    # Run logging in a separate thread to avoid blocking
    try {
        $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
        # For post-exec logging, the command that just finished is the last one in history.
        # The 'previous' command is the one before that.
        $prev = if ($history.Count -ge 2) { $history[-2].CommandLine } else { "" }
        
        $sb = [scriptblock]::Create("& '$Global:TermimBin' log '$($command.Replace("'", "''"))' --prev '$($prev.Replace("'", "''"))' --exit $exitCode --cwd '$($cwd.Replace("'", "''"))' 2>&1 | Out-Null")
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
        
        # Capture current directory for atomic context tagging
        $Global:TermimPreExecDir = (Get-Location).Path

        $currentLine = ""
        try { $currentLine = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
        catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $currentLine = $l }

        # Fetch and cache project history on first press
        if ($Global:TermimIdx -eq 0) {
            $Global:TermimOriginalInput = $currentLine
            if ($Global:TermimBin) {
                # Predictive Context: Get the last command run before this navigation
                $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
                $prev = if ($history.Count -gt 0) { $history[-1].CommandLine } else { "" }

                # Query with transition context
                $Global:TermimCache = @(& $Global:TermimBin query --prev "$prev" 2>$null | Select-Object -Unique)
            }
        }

        if ($Global:TermimCache.Length -gt 0 -and $Global:TermimIdx -lt $Global:TermimCache.Length) {
            $cmd = $Global:TermimCache[$Global:TermimIdx]
            if ($cmd -ne $currentLine) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $cmd)
            }
            $Global:TermimIdx++
        } else {
            # --- Escape Hatch: Fallback to Global Shell History ---
            [Microsoft.PowerShell.PSConsoleReadLine]::PreviousHistory($key, $arg)
        }
    }

    # Navigate project history with Down arrow
    Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
        param($key, $arg)

        $currentLine = ""
        try { $currentLine = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
        catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $currentLine = $l }

        if ($Global:TermimIdx -gt 0) {
            $Global:TermimIdx--
            if ($Global:TermimIdx -eq 0) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $Global:TermimOriginalInput)
            } else {
                $cmd = $Global:TermimCache[$Global:TermimIdx - 1]
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $currentLine.Length, $cmd)
            }
        } else {
            # --- Escape Hatch: Fallback to Global Shell History ---
            [Microsoft.PowerShell.PSConsoleReadLine]::NextHistory($key, $arg)
        }
    }

    # Log command on Enter (Mark as pending for post-exec logging)
    Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
        $line = ""
        try { $line = [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState().Content }
        catch { $l = ""; $c = 0; [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$l, [ref]$c); $line = $l }

        if ($line.Trim()) {
            $Global:TermimPendingCommand = $line
            # [v1.0.4] Absolute Context Capture
            $Global:TermimPreExecDir = (Get-Location).Path
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

# Post-Execution logic in the prompt function
function prompt {
    # 1. Capture exit status immediately (Must be first action)
    $lastExit = $LASTEXITCODE
    if ($null -eq $lastExit) { $lastExit = if ($?) { 0 } else { 1 } }

    # 2. Perform background logging for any pending command
    if ($Global:TermimPendingCommand) {
        if (Get-Command Invoke-TermimLogAsync -ErrorAction SilentlyContinue) {
            Invoke-TermimLogAsync -command $Global:TermimPendingCommand -exitCode $lastExit -cwd $Global:TermimPreExecDir
        }
        $Global:TermimPendingCommand = $null
        $Global:TermimPreExecDir = $null
    }

    # 3. Reset navigation state for the new prompt
    $Global:TermimIdx = 0
    $Global:TermimCache = @()
    
    # 4. Standard prompt output
    "PS $(Get-Location)> "
}
