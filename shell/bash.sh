# [v1.0.5] Universal Home Discovery: Find the physical .termim home on any platform
_TERMIM_HOME="$HOME/.termim"
if [[ ! -d "$_TERMIM_HOME" ]]; then
    # Fallback for Windows MSYS2/Git Bash: Map virtual home to physical Windows profile
    winHome="/c/Users/$USER/.termim"
    if [[ -d "$winHome" ]]; then
        _TERMIM_HOME="$winHome"
    else
        # Last resort: Try common drive letters
        for drive in i d e f; do
            if [[ -d "/$drive/Users/$USER/.termim" ]]; then
                _TERMIM_HOME="/$drive/Users/$USER/.termim"
                break
            fi
        done
    fi
fi

# Find the termim binary
_TERMIM_BIN="termim"
possiblePaths=("$_TERMIM_HOME/bin/termim.exe" "$_TERMIM_HOME/bin/termim" "$HOME/.termim/bin/termim.exe" "$HOME/.termim/bin/termim")
for p in "${possiblePaths[@]}"; do
    if [[ -x "$p" ]]; then
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
_TERMIM_PREEXEC_DIR=""

# Capture current directory before any command executes
_termim_preexec() {
    _TERMIM_PREEXEC_DIR="$PWD"
}
trap '_termim_preexec' DEBUG

# Log the last executed command
_termim_log() {
    local last_status=$? # Capture exit status immediately (must be first action)
    
    # Reset navigation on new prompt
    _TERMIM_IDX=0
    _TERMIM_CACHE=()

    # Get the last command from bash history
    local last_cmd
    last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Predictive Context: Get the penultimate command for transition recording
    local prev_cmd
    prev_cmd=$(fc -ln -2 -2 2>/dev/null | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ -n "$last_cmd" ]]; then
        # Run logging in background with explicit CWD and diagnostic logging
        ("$_TERMIM_BIN" log "$last_cmd" --prev "$prev_cmd" --exit "$last_status" --cwd "$_TERMIM_PREEXEC_DIR" 2>>"$_TERMIM_LOG" &) 
        disown 2>/dev/null
    fi
}

# Ensure log path exists or fallback to null (Hardened v1.2.6)
_TERMIM_LOG="$_TERMIM_HOME/termim.log"
if [[ ! -d "$(dirname "$_TERMIM_LOG" 2>/dev/null)" ]]; then
    _TERMIM_LOG="/dev/null"
fi

# Add logging hook to PROMPT_COMMAND (Hardened v1.2.6)
if [[ "$PROMPT_COMMAND" != *"_termim_log"* ]]; then
    if [[ -z "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="_termim_log"
    else
        PROMPT_COMMAND="_termim_log; $PROMPT_COMMAND"
    fi
fi
# Handle up arrow
_termim_up() {
    # First press: Capture input and fetch HISTORY ONLY
    if [[ $_TERMIM_IDX -le 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$READLINE_LINE"
        
        # Capture penultimate command for ranking
        local prev_cmd
        prev_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[ \t]*//;s/[ \t]*$//')

        # Termim: Project-aware terminal history and contextual intelligence v1.0.5
        mapfile -t _TERMIM_CACHE < <("$_TERMIM_BIN" query --history-only --prev "$prev_cmd" --cwd "$PWD" 2>/dev/null)
        _TERMIM_IDX=1
    else
        _TERMIM_IDX=$((_TERMIM_IDX + 1))
    fi
    
    if [[ $_TERMIM_IDX -le ${#_TERMIM_CACHE[@]} ]]; then
        local cmd="${_TERMIM_CACHE[$((_TERMIM_IDX - 1))]}"
        if [[ "$cmd" != "$READLINE_LINE" ]]; then
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        fi
    else
        # Fallback to standard global history
        local offset=$((_TERMIM_IDX - ${#_TERMIM_CACHE[@]}))
        local global_cmd
        global_cmd=$(history -p "!- $offset" 2>/dev/null)
        if [[ -n "$global_cmd" ]]; then
            READLINE_LINE="$global_cmd"
            READLINE_POINT=${#global_cmd}
        fi
    fi
}

# Handle down arrow
_termim_down() {
    if [[ $_TERMIM_IDX -gt ${#_TERMIM_CACHE[@]} ]]; then
        # ZONE: GLOBAL HISTORY (Symmetric Hand-off)
        _TERMIM_IDX=$((_TERMIM_IDX - 1))
        local offset=$((_TERMIM_IDX - ${#_TERMIM_CACHE[@]}))
        if [[ $offset -gt 0 ]]; then
            local global_cmd
            global_cmd=$(history -p "!- $offset" 2>/dev/null)
            if [[ -n "$global_cmd" ]]; then
                READLINE_LINE="$global_cmd"
                READLINE_POINT=${#global_cmd}
            fi
        else
             # Back to Project History frontier
             local cmd="${_TERMIM_CACHE[${#_TERMIM_CACHE[@]}-1]}"
             READLINE_LINE="$cmd"
             READLINE_POINT=${#cmd}
        fi
    elif [[ $_TERMIM_IDX -gt 0 ]]; then
        # ZONE: PROJECT HISTORY
        _TERMIM_IDX=$((_TERMIM_IDX - 1))
        if [[ $_TERMIM_IDX -eq 0 ]]; then
            # Neutral zone (Present)
            READLINE_LINE="$_TERMIM_ORIGINAL_INPUT"
            READLINE_POINT=${#_TERMIM_ORIGINAL_INPUT}
        else
            local cmd="${_TERMIM_CACHE[$((_TERMIM_IDX - 1))]}"
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        fi
    elif [[ $_TERMIM_IDX -eq 0 && ${READLINE_LINE// /} == "" ]]; then
        # INTELLIGENCE TRIGGER (Future): Trigger prediction on empty prompt
        local prev_cmd
        prev_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[ \t]*//;s/[ \t]*$//')
        
        # Fetch strictly predictions-only
        mapfile -t _TERMIM_CACHE < <("$_TERMIM_BIN" query --suggest-only --prev "$prev_cmd" --cwd "$PWD" 2>/dev/null)
        
        if [[ ${#_TERMIM_CACHE[@]} -gt 0 ]]; then
            _TERMIM_IDX=-1
            local cmd="${_TERMIM_CACHE[0]}"
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        fi
    elif [[ $_TERMIM_IDX -lt 0 ]]; then
        # Cycling through Predictions (Future)
        local abs_idx=${_TERMIM_IDX#-}
        if [[ $abs_idx -lt ${#_TERMIM_CACHE[@]} ]]; then
            _TERMIM_IDX=$((_TERMIM_IDX - 1))
            abs_idx=${_TERMIM_IDX#-}
            local cmd="${_TERMIM_CACHE[$((abs_idx - 1))]}"
            READLINE_LINE="$cmd"
            READLINE_POINT=${#cmd}
        fi
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
        "$_TERMIM_BIN" query --cwd "$PWD" 2>/dev/null > "$tmp_hist"

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
