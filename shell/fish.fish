# Find the termim binary
set -g _TERMIM_BIN "termim"
set -l userHome (eval echo "~$USER")
set -l possiblePaths "$HOME/.termim/bin/termim"
set -a possiblePaths "$HOME/.termim/bin/termim.exe"
set -a possiblePaths "$userHome/.termim/bin/termim"
set -a possiblePaths "/c/Users/$USER/.termim/bin/termim.exe"
set -a possiblePaths "/c/Users/$USER/.termim/bin/termim"

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

# Navigation state
set -g _TERMIM_IDX 0
set -g _TERMIM_CACHE
set -g _TERMIM_ORIGINAL_INPUT ""

# Log commands in the background
function termim_preexec --on-event fish_preexec
    # Only log if termim is found
    if not type -q "$_TERMIM_BIN"
        return
    end

    # Get the command from the arguments
    set -l cmd $argv[1]
    if test -z "$cmd"
        return
    end

    # Background logging with disown to stay silent
    "$_TERMIM_BIN" log "$cmd" >/dev/null 2>&1 &
    disown 2>/dev/null
    
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

# Use up arrow to navigate project history
function termim_up
    # Fetch history if not already cached
    if test $_TERMIM_IDX -eq 0
        set -g _TERMIM_ORIGINAL_INPUT (commandline)
        set -g _TERMIM_CACHE ("$_TERMIM_BIN" query 2>/dev/null)
    end

    set -l next_idx (math $_TERMIM_IDX + 1)
    
    # Cycle through in-memory cache
    if test $next_idx -le (count $_TERMIM_CACHE)
        set -l cmd $_TERMIM_CACHE[$next_idx]
        # Only update if the command is different
        if test "$cmd" != (commandline)
            set -g _TERMIM_IDX $next_idx
            commandline $cmd
            commandline -C (string length $cmd)
        end
    end
end

# Down arrow navigation
function termim_down
    if test $_TERMIM_IDX -le 0
        return
    end

    set -l next_idx (math $_TERMIM_IDX - 1)
    
    if test $next_idx -eq 0
        # Restore original input
        if test (commandline) != "$_TERMIM_ORIGINAL_INPUT"
            commandline $_TERMIM_ORIGINAL_INPUT
            commandline -C (string length $_TERMIM_ORIGINAL_INPUT)
        end
        set -g _TERMIM_IDX 0
    else if test $next_idx -le (count $_TERMIM_CACHE)
        set -l cmd $_TERMIM_CACHE[$next_idx]
        if test "$cmd" != (commandline)
            set -g _TERMIM_IDX $next_idx
            commandline $cmd
            commandline -C (string length $cmd)
        else
            set -g _TERMIM_IDX $next_idx
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
    "$_TERMIM_BIN" query 2>/dev/null > "$tmp_hist"

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
