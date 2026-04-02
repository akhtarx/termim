# Termim Bash Integration — with Stateful Native Mastery
# Mastery Edition: Global Gold Standard (Resilient & Silky Smooth)
# Source from ~/.bashrc:  source ~/.termim/shell/bash.sh

# --- 1. Universal Path Strategy & Fallback ---

_TERMIM_BIN=""
_user_home_win="/c/Users/$USER"
_user_home_wsl="/mnt/c/Users/$USER"

# Scan Strategy: MSYS2 -> WSL -> Native
for p in "$_user_home_win/.termim/bin/termim" "$_user_home_wsl/.termim/bin/termim" "$HOME/.termim/bin/termim"; do
    if [[ -x "$p" ]]; then
        _TERMIM_BIN="$p"
        # Ensure it's in PATH for this session
        export PATH="$(dirname "$p"):$PATH"
        break
    fi
done

# --- 2. State Management (The Mastery Pointer) ---

_TERMIM_IDX=0
_TERMIM_LAST_CMD=""
_TERMIM_ORIGINAL_INPUT=""
_TERMIM_CACHE=()

# 3. Silent Command Logging (Direct-to-Disk CLI)
_termim_log() {
    # Check for binary existence (Fail-Safe)
    [[ -z "$_TERMIM_BIN" ]] && return
    
    local last_cmd
    last_cmd=$(HISTTIMEFORMAT='' history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
    
    if [[ -n "$last_cmd" && "$last_cmd" != "$_TERMIM_LAST_CMD" ]]; then
        # Silent Background Logging (Maverick Subshell Trick)
        ("$_TERMIM_BIN" log "$last_cmd" &>/dev/null &) 
        _TERMIM_LAST_CMD="$last_cmd"
        _TERMIM_IDX=0 
        _TERMIM_CACHE=() 
    fi
}

# Attach to PROMPT_COMMAND for automatic logging and index reset
if [[ "$PROMPT_COMMAND" != *"_termim_log"* ]]; then
    PROMPT_COMMAND="_termim_log; $PROMPT_COMMAND"
fi

# 4. Stateful Up-arrow: project history (Native Readline)
_termim_up() {
    # Fail-Safe check
    [[ -z "$_TERMIM_BIN" ]] && return

    # 1. Initialize Cache on first press (Industrial Latency Fix)
    if [[ $_TERMIM_IDX -eq 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$READLINE_LINE"
        # Access In-Memory Array for 0ms recall
        mapfile -t _TERMIM_CACHE < <("$_TERMIM_BIN" query 2>/dev/null)
    fi

    local next_idx=$((_TERMIM_IDX + 1))
    
    if [[ $next_idx -le ${#_TERMIM_CACHE[@]} ]]; then
        local cmd="${_TERMIM_CACHE[$((next_idx - 1))]}"
        # Anti-Flicker: Only update if the content is DIFFERENT
        if [[ "$cmd" != "$READLINE_LINE" ]]; then
            _TERMIM_IDX=$next_idx
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        else
            _TERMIM_IDX=$next_idx
        fi
    fi
}

# 5. Stateful Down-arrow: project history
_termim_down() {
    if [[ $_TERMIM_IDX -le 0 ]]; then
        return
    fi

    local next_idx=$((_TERMIM_IDX - 1))
    
    if [[ $next_idx -eq 0 ]]; then
        # Anti-Flicker: Only update if different
        if [[ "$READLINE_LINE" != "$_TERMIM_ORIGINAL_INPUT" ]]; then
            _TERMIM_IDX=0
            READLINE_LINE="$_TERMIM_ORIGINAL_INPUT"
            READLINE_POINT=${#_TERMIM_ORIGINAL_INPUT}
        else
            _TERMIM_IDX=0
        fi
    elif [[ $next_idx -le ${#_TERMIM_CACHE[@]} ]]; then
        local cmd="${_TERMIM_CACHE[$((next_idx - 1))]}"
        if [[ "$cmd" != "$READLINE_LINE" ]]; then
            _TERMIM_IDX=$next_idx
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        else
            _TERMIM_IDX=$next_idx
        fi
    fi
}

# 6. Bind standard Bash (\e[A) and MinTTY/GitBash (\eOA)
bind -x '"\e[A": _termim_up'
bind -x '"\eOA": _termim_up'
bind -x '"\e[B": _termim_down'
bind -x '"\eOB": _termim_down'

# 7. Ctrl+P: Interactive Palette (Requires fzf)
_termim_palette() {
    if ! command -v fzf &>/dev/null; then
        echo -e "\n[termim] install 'fzf' to use the Ctrl+P palette."
        return 1
    fi
    [[ -z "$_TERMIM_BIN" ]] && return

    local selected
    selected=$("$_TERMIM_BIN" query 2>/dev/null | fzf \
        --height=40% \
        --reverse \
        --border=rounded \
        --prompt="  termim > " \
        --header="Project History" \
        --no-sort \
        2>/dev/null)
        
    if [[ -n "$selected" ]]; then
        READLINE_LINE="$selected"
        READLINE_POINT=${#selected}
        _TERMIM_IDX=0 
        _TERMIM_CACHE=()
    fi
}
bind -x '"\C-p": _termim_palette'
