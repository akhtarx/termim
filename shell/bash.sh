# Find the termim binary
_TERMIM_BIN="termim"
userHome=$(eval echo "~$USER")
possiblePaths=(
    "$HOME/.termim/bin/termim"
    "$HOME/.termim/bin/termim.exe"
    "$userHome/.termim/bin/termim"
    "/c/Users/$USER/.termim/bin/termim.exe"
)

for p in "${possiblePaths[@]}"; do
    if [[ -x "$p" || -f "$p" ]]; then
        _TERMIM_BIN="$p"
        # Ensure bin is in PATH
        binDir=$(dirname "$p")
        [[ ":$PATH:" != *":$binDir:"* ]] && export PATH="$binDir:$PATH"
        break
    fi
done

# History navigation state
_TERMIM_IDX=0
_TERMIM_LAST_CMD=""
_TERMIM_ORIGINAL_INPUT=""
_TERMIM_CACHE=()

# Log the last executed command
_termim_log() {
    # Reset navigation on new prompt
    _TERMIM_IDX=0
    _TERMIM_CACHE=()

    # Get the last command from bash history
    local last_cmd
    last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ -n "$last_cmd" ]]; then
        # Run logging in background and disown to keep terminal clean
        ("$_TERMIM_BIN" log "$last_cmd" &>/dev/null &) 
        disown 2>/dev/null
    fi
}

# Add logging hook to PROMPT_COMMAND
if [[ "$PROMPT_COMMAND" != *"_termim_log"* ]]; then
    PROMPT_COMMAND="_termim_log; $PROMPT_COMMAND"
fi

# Handle up arrow
_termim_up() {
    # Fetch project history on first press
    if [[ $_TERMIM_IDX -eq 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$READLINE_LINE"
        mapfile -t _TERMIM_CACHE < <("$_TERMIM_BIN" query 2>/dev/null)
    fi
    local next_idx=$((_TERMIM_IDX + 1))
    
    # Navigate if history is available
    if [[ $next_idx -le ${#_TERMIM_CACHE[@]} ]]; then
        local cmd="${_TERMIM_CACHE[$((next_idx - 1))]}"
        # Only update if the command is different
        if [[ "$cmd" != "$READLINE_LINE" ]]; then
            _TERMIM_IDX=$next_idx
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        fi
    else
        # --- Escape Hatch: Fallback to Global Shell History (Simulated) ---
        local global_cmd
        global_cmd=$(history -p "!- $((next_idx - ${#_TERMIM_CACHE[@]}))" 2>/dev/null)
        if [[ -n "$global_cmd" ]]; then
            _TERMIM_IDX=$next_idx
            READLINE_LINE="$global_cmd"
            READLINE_POINT=${#global_cmd}
        fi
    fi
}

# Handle down arrow
_termim_down() {
    if [[ $_TERMIM_IDX -gt 0 ]]; then
        local next_idx=$((_TERMIM_IDX - 1))
        
        if [[ $next_idx -eq 0 ]]; then
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
    else
        # --- Escape Hatch: Fallback to Global Shell History (Simulated) ---
        # We don't implement full bidirectional global history for Bash due to its 
        # stateless bind -x nature, but we allow simple recovery.
        return
    fi
}

# Bind keys for standard and MinTTY/GitBash terminals
if [[ $- == *i* ]]; then
    bind -x '"\e[A": _termim_up'
    bind -x '"\eOA": _termim_up'
    bind -x '"\e[B": _termim_down'
    bind -x '"\eOB": _termim_down'

    # Search for fzf if not in PATH
    _FZF_BIN="fzf"
    if ! command -v fzf &>/dev/null; then
        # Check Windows path
        win_fzf=$(where.exe fzf 2>/dev/null | head -n 1)
        if [[ -n "$win_fzf" ]]; then
            _FZF_BIN=$(cygpath -u "$win_fzf" 2>/dev/null)
        else
            # Manual fallbacks
            fzfPaths=(
                "/c/ProgramData/chocolatey/bin/fzf.exe"
                "$HOME/scoop/shims/fzf.exe"
                "/c/Users/$USER/scoop/shims/fzf.exe"
                "/c/tools/fzf/fzf.exe"
            )
            for p in "${fzfPaths[@]}"; do
                if [[ -f "$p" ]]; then
                    _FZF_BIN="$p"
                    break
                fi
            done
        fi
    fi

    # Interactive search palette
    _termim_palette() {
        if ! command -v "$_FZF_BIN" &>/dev/null && [[ ! -f "$_FZF_BIN" ]]; then
            echo -e "\n[termim] fzf not found. Install fzf to use Ctrl+P."
            return 1
        fi

        local fzf_cmd="$_FZF_BIN"
        # Use winpty for Windows-native fzf in Git Bash
        if command -v winpty &>/dev/null && "$_FZF_BIN" --version 2>/dev/null | grep -q "windows"; then
            fzf_cmd="winpty $_FZF_BIN"
        fi

        # Use temp file to avoid TTY issues with bind -x
        local tmp_hist
        tmp_hist=$(mktemp)
        "$_TERMIM_BIN" query 2>/dev/null > "$tmp_hist"

        local selected
        selected=$($fzf_cmd \
            --height=40% \
            --reverse \
            --border=rounded \
            --prompt="  termim > " \
            --header="Project History" \
            --no-sort \
            < "$tmp_hist")
        
        rm -f "$tmp_hist"
            
        if [[ -n "$selected" ]]; then
            READLINE_LINE="$selected"
            READLINE_POINT=${#selected}
            _TERMIM_IDX=0 
            _TERMIM_CACHE=()
        fi
        
        # Repaint buffer
        history -s "$READLINE_LINE"
    }

    # Bind Ctrl+P to the palette
    bind -x '"\C-p": _termim_palette'
    bind -x '"\cp": _termim_palette'
fi
