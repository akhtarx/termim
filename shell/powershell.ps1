# Termim PowerShell Integration
# Version 1.0.9
# Source from $PROFILE: . "$HOME\.termim\shell\powershell.ps1"

# [v1.2.0] Universal Home Discovery: Find the physical .termim home on any platform
$Global:TermimHome = "$HOME\.termim"
if (-not (Test-Path $Global:TermimHome)) {
    # Fallback for Windows MSYS2/PowerShell identity drift: Map to physical profile
    $userHome = [System.Environment]::GetFolderPath("UserProfile")
    $winHome = "$userHome\.termim"
    if (Test-Path $winHome) {
        $Global:TermimHome = $winHome
    } else {
        # Last resort: Scan common drives (I, D, E, F)
        foreach ($drive in @("I", "D", "E", "F")) {
            if (Test-Path "$($drive):\Users\$($env:USERNAME)\.termim") {
                $Global:TermimHome = "$($drive):\Users\$($env:USERNAME)\.termim"
                break
            }
        }
    }
}

# Find the termim binary
$Global:TermimBin = ""
$possiblePaths = @(
    "$Global:TermimHome\bin\termim.exe", 
    "$Global:TermimHome\bin\termim",
    "$HOME\.termim\bin\termim.exe"
)

foreach ($p in $possiblePaths) {
    if (Test-Path $p) {
        $Global:TermimBin = $p
        $binDir = [System.IO.Path]::GetDirectoryName($p)
        if ($env:PATH -notlike "*$binDir*") { $env:PATH = "$binDir;$env:PATH" }
        break
    }
}


# Background logging with runspaces (Silenced v1.1.9)
$null = ($Global:TermimLogger = [powershell]::Create())
$null = ($Global:TermimLogger.Runspace = [runspacefactory]::CreateRunspace())
$null = $Global:TermimLogger.Runspace.Open()

function Global:Invoke-TermimLogAsync {
    param([string]$command, [int]$exitCode = 0, [string]$cwd = "", [string]$branch = "none")
    if (-not $Global:TermimBin) { return }
    
    # Run logging in a separate thread to avoid blocking
    try {
        $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
        # For post-exec logging, the command that just finished is the last one in history.
        # The 'previous' command is the one before that.
        $prev = if ($history.Count -ge 2) { $history[-2].CommandLine } else { "" }
        
        $sb = [scriptblock]::Create("& '$Global:TermimBin' log '$($command.Replace("'", "''"))' --prev '$($prev.Replace("'", "''"))' --exit $exitCode --cwd '$($cwd.Replace("'", "''"))' --branch '$($branch.Replace("'", "''"))' 2>>`"$Global:TermimHome\termim.log`"")
        $Global:TermimLogger.Commands.Clear() | Out-Null
        $Global:TermimLogger.AddScript($sb) | Out-Null
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

    # Up Arrow: Project-Aware History (Past)
    Set-PSReadLineKeyHandler -Key UpArrow -ScriptBlock {
        $line = ""
        $cursor = 0
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # First press: Capture original input and fetch HISTORY ONLY
        if ($Global:TermimIdx -le 0) {
            $Global:TermimOriginalInput = $line
            # [v1.5.0] Absolute Context Capture: Update directory before query
            $Global:TermimPreExecDir = (Get-Location).Path
            
            # Capture penultimate command for ranking context
            $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
            $prev = if ($history.Count -gt 0) { $history[-1].CommandLine } else { "" }
            
            # Fetch strictly history-only results (Recency)
            $branch = (git branch --show-current 2>$null)
            if (-not $branch) { $branch = "none" }
            $Global:TermimCache = @(& $Global:TermimBin query --history-only --prev "$prev" --cwd "$Global:TermimPreExecDir" --branch "$branch" 2>$null | Select-Object -Unique)
            $Global:TermimIdx = 1
        } else {
            $Global:TermimIdx++
        }

        if ($Global:TermimIdx -le $Global:TermimCache.Count) {
            $cmd = $Global:TermimCache[$Global:TermimIdx - 1]
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $cmd)
        } else {
            # Fallback to standard global history
            [Microsoft.PowerShell.PSConsoleReadLine]::PreviousHistory($null, $null)
        }
    }

    # Down Arrow: Project-Aware Restore OR Intelligent Prediction (Future)
    Set-PSReadLineKeyHandler -Key DownArrow -ScriptBlock {
        $line = ""
        $cursor = 0
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($Global:TermimIdx -gt $Global:TermimCache.Count) {
            # ZONE: GLOBAL HISTORY (Symmetric Hand-off)
            $Global:TermimIdx--
            [Microsoft.PowerShell.PSConsoleReadLine]::NextHistory($null, $null)
        } elseif ($Global:TermimIdx -gt 0) {
            # ZONE: PROJECT HISTORY
            $Global:TermimIdx--
            if ($Global:TermimIdx -eq 0) {
                # Back to Neutral (Present)
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $Global:TermimOriginalInput)
            } else {
                $cmd = $Global:TermimCache[$Global:TermimIdx - 1]
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $cmd)
            }
        } elseif ($Global:TermimIdx -eq 0 -and $line.Trim() -eq "") {
            # INTELLIGENCE TRIGGER (Future): Trigger prediction on empty prompt
            $Global:TermimPreExecDir = (Get-Location).Path
            $history = [Microsoft.PowerShell.PSConsoleReadLine]::GetHistoryItems()
            $prev = if ($history.Count -gt 0) { $history[-1].CommandLine } else { "" }
            
            # Fetch strictly predictions-only
            $branch = (git branch --show-current 2>$null)
            if (-not $branch) { $branch = "none" }
            $Global:TermimCache = @(& $Global:TermimBin query --suggest-only --prev "$prev" --cwd "$Global:TermimPreExecDir" --branch "$branch" 2>$null | Where-Object { $_.Trim() -ne "" } | Select-Object -Unique)
            
            if ($Global:TermimCache.Count -gt 0) {
                $Global:TermimIdx = -1
                $cmd = $Global:TermimCache[0]
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $cmd)
            }
            # Otherwise stay blank (No fallback to standard history)
        } elseif ($Global:TermimIdx -lt 0) {
            # Cycling through Predictions (Future)
            if ([System.Math]::Abs($Global:TermimIdx) -lt $Global:TermimCache.Count) {
                $Global:TermimIdx--
                $cmd = $Global:TermimCache[[System.Math]::Abs($Global:TermimIdx) - 1]
                [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $cmd)
            }
            # Otherwise stay at the end of predictions (No fallback to standard history)
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
            # Capture current directory context
            $Global:TermimPreExecDir = (Get-Location).Path
            $branch = (git branch --show-current 2>$null)
            if (-not $branch) { $branch = "none" }
            $history = & $Global:TermimBin query --cwd "$Global:TermimPreExecDir" --branch "$branch" 2>$null | Select-Object -Unique
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
            $branch = (git branch --show-current 2>$null)
            if (-not $branch) { $branch = "none" }
            Invoke-TermimLogAsync -command $Global:TermimPendingCommand -exitCode $lastExit -cwd $Global:TermimPreExecDir -branch $branch
        }
        $Global:TermimPendingCommand = $null
        $Global:TermimPreExecDir = $null
    }
    
    # 5. v1.0.9: Export last status for query-time context weighting
    $env:TERMIM_LAST_EXIT = $lastExit

    # 3. Reset navigation state for the new prompt
    $Global:TermimIdx = 0
    $Global:TermimCache = @()
    
    # 4. Standard prompt output
    "PS $(Get-Location)> "
}
