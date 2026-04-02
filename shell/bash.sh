# Termim Bash Integration — with Stateful Native Mastery
# Source from ~/.bashrc:  source ~/.termim/shell/bash.sh

# 1. Update PATH for this session
export PATH="$HOME/.termim/bin:$PATH"

# 2. State Management (The Mastery Pointer)
_TERMIM_IDX=0
_TERMIM_LAST_CMD=""
_TERMIM_ORIGINAL_INPUT=""
_TERMIM_CACHE=()

# 3. Silent Command Logging (Direct-to-Disk CLI)
_termim_log() {
    local last_cmd
    # Get the last command from history
    last_cmd=$(HISTTIMEFORMAT='' history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
    
    if [[ -n "$last_cmd" && "$last_cmd" != "$_TERMIM_LAST_CMD" ]]; then
        # Silent Background Logging (Maverick Subshell Trick)
        (termim log "$last_cmd" &>/dev/null &) 
        _TERMIM_LAST_CMD="$last_cmd"
        _TERMIM_IDX=0 # Reset history index on new command
        _TERMIM_CACHE=() # Purge navigation cache
    fi
}

# Attach to PROMPT_COMMAND for automatic logging and index reset
if [[ "$PROMPT_COMMAND" != *"_termim_log"* ]]; then
    PROMPT_COMMAND="_termim_log; $PROMPT_COMMAND"
fi

# 4. Stateful Up-arrow: project history (Native Readline)
_termim_up() {
    # Initialize Cache on first press (Industrial Latency Fix)
    if [[ $_TERMIM_IDX -eq 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$READLINE_LINE"
        mapfile -t _TERMIM_CACHE < <(termim query 2>/dev/null)
    fi

    local next_idx=$((_TERMIM_IDX + 1))
    
    # Anti-Flicker Master Check
    if [[ $next_idx -le ${#_TERMIM_CACHE[@]} ]]; then
        local cmd="${_TERMIM_CACHE[$((next_idx - 1))]}"
        # Only redraw if the content is DIFFERENT (Silky Smooth)
        if [[ "$cmd" != "$READLINE_LINE" ]]; then
            _TERMIM_IDX=$next_idx
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
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
        # Only restore original if it's different to prevent flicker
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

    local selected
    selected=$(termim query 2>/dev/null | fzf \
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
