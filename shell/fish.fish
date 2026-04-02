# Termim Fish Integration — with Stateful Native Mastery (Silky Smooth)
# Mastery Edition: Global Gold Standard (Resilient & Silky Smooth)
# Add to ~/.config/fish/config.fish:  source ~/.termim/shell/fish.fish

# --- 1. Universal Path Strategy & Fallback ---

set -g _TERMIM_BIN ""
set -l user_home_win "/c/Users/$USER"
set -l user_home_wsl "/mnt/c/Users/$USER"

# Scan Strategy: MSYS2 -> WSL -> Native
for p in "$user_home_win/.termim/bin/termim" "$user_home_wsl/.termim/bin/termim" "$HOME/.termim/bin/termim"
    if test -x "$p"
        set -g _TERMIM_BIN "$p"
        # Ensure it's in PATH for this session
        if not contains (dirname "$p") $PATH
            set -gx PATH (dirname "$p") $PATH
        end
        break
    end
end

# --- 2. State Management (The Mastery Pointer) ---

set -g _TERMIM_IDX 0
set -g _TERMIM_CACHE
set -g _TERMIM_ORIGINAL_INPUT ""

# 3. Command logging (Direct-to-Disk CLI)
function termim_preexec --on-event fish_preexec
    # Fail-Safe check
    if test -n "$_TERMIM_BIN"
        # Silent Background Logging (Native Fish Async)
        "$_TERMIM_BIN" log "$argv[1]" >/dev/null 2>&1 &
    end
    set -g _TERMIM_IDX 0 
    set -e _TERMIM_CACHE 
end

# 4. Stateful Up-arrow: project history (Native Fish Commandline)
function termim_up
    # Fail-Safe: Native fallback if binary is missing
    if test -z "$_TERMIM_BIN"
        commandline -f up-or-search
        return
    end

    # 1. Initialize Cache on first press (Industrial Latency Fix)
    if test $_TERMIM_IDX -eq 0
        set -g _TERMIM_ORIGINAL_INPUT (commandline)
        set -g _TERMIM_CACHE ("$_TERMIM_BIN" query 2>/dev/null)
    end

    if test (count $_TERMIM_CACHE) -eq 0
        commandline -f up-or-search
        return
    end

    set -l next_idx (math $_TERMIM_IDX + 1)
    
    # 2. Access In-Memory Array for 0ms recall (1-based index)
    if test $next_idx -le (count $_TERMIM_CACHE)
        set -l cmd $_TERMIM_CACHE[$next_idx]
        # Anti-Flicker: Only update if the content is DIFFERENT
        if test "$cmd" != (commandline)
            set -g _TERMIM_IDX $next_idx
            commandline $cmd
            commandline -C (string length $cmd)
        else
            set -g _TERMIM_IDX $next_idx
        end
    end
end

# 5. Stateful Down-arrow: project history
function termim_down
    if test $_TERMIM_IDX -le 0
        commandline -f down-or-search
        return
    end

    set -l next_idx (math $_TERMIM_IDX - 1)
    
    if test $next_idx -eq 0
        # Restore original input from memory (with anti-flicker diff)
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

# 6. Bind standard Fish sequences
bind \e\[A termim_up
bind \eOA termim_up
bind \e\[B termim_down
bind \eOB termim_down

# 7. Ctrl+P: Interactive Palette (Requires fzf)
function termim_palette
    if not command -v fzf >/dev/null 2>&1
        echo -e "\n[termim] install 'fzf' to use the Ctrl+P palette."
        commandline -f repaint
        return 1
    end
    if test -z "$_TERMIM_BIN"
        return
    end

    set -l selected ("$_TERMIM_BIN" query 2>/dev/null | fzf \
        --height=40% \
        --reverse \
        --border=rounded \
        --prompt="  termim > " \
        --header="Project History" \
        --no-sort \
        2>/dev/null)
        
    if test -n "$selected"
        commandline $selected
        commandline -C (string length $selected)
        set -g _TERMIM_IDX 0
        set -e _TERMIM_CACHE
    end
    commandline -f repaint
end
bind \cp termim_palette
