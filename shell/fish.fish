# [v1.0.9] Universal Home Discovery
set -g _TERMIM_HOME "$HOME/.termim"
if not test -d "$_TERMIM_HOME"
    # Fallback for Windows MSYS2/Git Bash/Fish: Map virtual home to physical Windows home
    set -l winHome "/c/Users/$USER/.termim"
    if test -d "$winHome"
        set -g _TERMIM_HOME "$winHome"
    else
        # Last resort: Try common drive letters (I, D, E)
        for drive in i d e f
            if test -d "/$drive/Users/$USER/.termim"
                set -g _TERMIM_HOME "/$drive/Users/$USER/.termim"
                break
            end
        end
    end
end

# Find the termim binary
set -g _TERMIM_BIN "termim"
set -l possiblePaths "$_TERMIM_HOME/bin/termim"
set -a possiblePaths "$_TERMIM_HOME/bin/termim.exe"
set -a possiblePaths "$HOME/.termim/bin/termim"
set -a possiblePaths "$HOME/.termim/bin/termim.exe"

for p in $possiblePaths
    if test -f "$p"; or test -x "$p"
        set -g _TERMIM_BIN "$p"
        set -l binDir (dirname "$p")
        if not contains "$binDir" $PATH
            set -gx PATH "$binDir" $PATH
        end
        break
    end
end

# Ensure log path exists or fallback to null
set -g _TERMIM_LOG "$_TERMIM_HOME/termim.log"
if not test -d (dirname "$_TERMIM_LOG" 2>/dev/null)
    set -g _TERMIM_LOG "/dev/null"
end

# Navigation state
set -g _TERMIM_IDX 0
set -g _TERMIM_CACHE
set -g _TERMIM_ORIGINAL_INPUT ""
set -g _TERMIM_PREEXEC_DIR ""

# Capture directory before command execution
function _termim_preexec --on-event fish_preexec
    set -g _TERMIM_PREEXEC_DIR $PWD
end

# Post-Execution logic in Fish: Capture exit status and log
function termim_postexec --on-event fish_postexec
    # Only log if termim is found
    if not type -q "$_TERMIM_BIN"
        return
    end

    # Command and its exit status from arguments
    set -l cmd $argv[1]
    set -l exit_status $argv[2]
    
    if test -z "$cmd"
        return
    end

    # Behavioral Context: Get the penultimate command (since current is at head)
    set -l prev (history | head -n 2 | tail -n 1)

    # Log to Termim with explicit CWD, branch detection and diagnostic logging
    set -l branch (git branch --show-current 2>/dev/null; or echo "none")
    "$_TERMIM_BIN" log "$cmd" --prev "$prev" --exit "$exit_status" --cwd "$_TERMIM_PREEXEC_DIR" --branch "$branch" 2>>"$_TERMIM_LOG" &
    disown 2>/dev/null
    
    set -g _TERMIM_PREEXEC_DIR ""
    
    # v1.0.9: Set last status for query-time context weighting
    set -gx TERMIM_LAST_EXIT "$exit_status"
    
    # Reset navigation state on new command
    set -g _TERMIM_IDX 0 
    set -e _TERMIM_CACHE 
end

# Optional: Seed session history with project history
if status is-interactive
    "$_TERMIM_BIN" query 2>/dev/null | while read -l cmd
        # history add "$cmd" --no-save
    end
end

# Use up arrow to navigate project history (Past)
function termim_up
    # First press: Capture input and fetch HISTORY ONLY
    if test $_TERMIM_IDX -le 0
        set -g _TERMIM_ORIGINAL_INPUT (commandline)
        
        # Capture context for ranking
        set -l prev_cmd (history | head -n 1)
        set -l branch (git branch --show-current 2>/dev/null; or echo "none")
        set -g _TERMIM_CACHE ("$_TERMIM_BIN" query --history-only --prev "$prev_cmd" --cwd (pwd) --branch "$branch" 2>/dev/null)
        set -g _TERMIM_IDX 1
    else
        set -g _TERMIM_IDX (math $_TERMIM_IDX + 1)
    end

    # Cycle through in-memory history cache
    if test $_TERMIM_IDX -le (count $_TERMIM_CACHE)
        set -l cmd $_TERMIM_CACHE[$_TERMIM_IDX]
        if test "$cmd" != (commandline)
            commandline $cmd
            commandline -C (string length $cmd)
        end
    else
        # Fallback to standard global history
        commandline -f up-line
    end
end

# Down arrow navigation: History Restore OR Intelligent Prediction (Future)
function termim_down
    if test $_TERMIM_IDX -gt (count $_TERMIM_CACHE)
        # ZONE: GLOBAL HISTORY (Symmetric Hand-off)
        set -g _TERMIM_IDX (math $_TERMIM_IDX - 1)
        commandline -f down-line
    else if test $_TERMIM_IDX -gt 0
        # ZONE: PROJECT HISTORY
        set -g _TERMIM_IDX (math $_TERMIM_IDX - 1)
        if test $_TERMIM_IDX -eq 0
            # Neutral zone (Present)
            commandline $_TERMIM_ORIGINAL_INPUT
            commandline -C (string length $_TERMIM_ORIGINAL_INPUT)
        else
            set -l cmd $_TERMIM_CACHE[$_TERMIM_IDX]
            commandline $cmd
            commandline -C (string length $cmd)
        end
    else if test $_TERMIM_IDX -eq 0; and test (string trim (commandline)) = ""
        # INTELLIGENCE TRIGGER (Future): Trigger prediction on empty prompt
        set -l prev_cmd (history | head -n 1)
        
        # Fetch strictly predictions-only
        set -l branch (git branch --show-current 2>/dev/null; or echo "none")
        set -g _TERMIM_CACHE ("$_TERMIM_BIN" query --suggest-only --prev "$prev_cmd" --cwd (pwd) --branch "$branch" 2>/dev/null)
        
        if test (count $_TERMIM_CACHE) -gt 0
            set -g _TERMIM_IDX -1
            set -l cmd $_TERMIM_CACHE[1]
            commandline $cmd
            commandline -C (string length $cmd)
        end
    else if test $_TERMIM_IDX -lt 0
        # Cycling through Predictions (Future)
        set -l abs_idx (math abs $_TERMIM_IDX)
        if test $abs_idx -lt (count $_TERMIM_CACHE)
            set -g _TERMIM_IDX (math $_TERMIM_IDX - 1)
            set abs_idx (math abs $_TERMIM_IDX)
            set -l cmd $_TERMIM_CACHE[$abs_idx]
            commandline $cmd
            commandline -C (string length $cmd)
        end
    end
end

# Bind keys for standard and MinTTY terminals
bind \e\[A termim_up
bind \eOA termim_up
bind \e\[B termim_down
bind \eOB termim_down

# Search for fzf if missing from PATH
set -g _FZF_BIN "fzf"
if not type -q fzf
    # Check Windows path
    set -l win_fzf (where.exe fzf 2>/dev/null | head -n 1)
    if test -n "$win_fzf"
        # Convert C:\... to /c/... for Fish
        set -g _FZF_BIN (cygpath -u "$win_fzf" 2>/dev/null)
    else
        # Fallback search paths
        set -l fzfPaths "/c/ProgramData/chocolatey/bin/fzf.exe"
        set -a fzfPaths "$HOME/scoop/shims/fzf.exe"
        set -a fzfPaths "/c/Users/$USER/scoop/shims/fzf.exe"
        set -a fzfPaths "/c/tools/fzf/fzf.exe"
        for p in $fzfPaths
            if test -f "$p"
                set -g _FZF_BIN "$p"
                break
            end
        end
    end
end

# Interactive search palette
function termim_palette
    if not type -q "$_FZF_BIN"; and not test -f "$_FZF_BIN"
        echo -e "\n[termim] fzf not found. Install fzf to use Ctrl+P."
        commandline -f repaint
        return 1
    end

    # Use winpty for Windows-native fzf
    set -l fzf_cmd "$_FZF_BIN"
    if command -v winpty &>/dev/null; and "$_FZF_BIN" --version 2>/dev/null | string match -q "*windows*"
        set fzf_cmd "winpty $_FZF_BIN"
    end

    # Use temp file to avoid TTY issues
    set -l tmp_hist (mktemp)
    set -l branch (git branch --show-current 2>/dev/null; or echo "none")
    "$_TERMIM_BIN" query --cwd (pwd) --branch "$branch" 2>/dev/null > "$tmp_hist"

    set -l selected (cat "$tmp_hist" | $fzf_cmd \
        --height=40% \
        --reverse \
        --border=rounded \
        --prompt="  termim > " \
        --header="Project History" \
        --no-sort)
        
    rm -f "$tmp_hist"
        
    if test -n "$selected"
        commandline $selected
        commandline -C (string length $selected)
        set -g _TERMIM_IDX 0
        set -e _TERMIM_CACHE
    end
    commandline -f repaint
end
bind \cp termim_palette
