#!/usr/bin/env zsh
# Termim Zsh Integration
# Compatible with MSYS/Git Bash and macOS

# [v1.0.7] Universal Home Discovery: Find the physical .termim home on any platform
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
for p in $possiblePaths; do
    if [[ -f "$p" || -x "$p" ]]; then
        _TERMIM_BIN="$p"
        binDir=$(dirname "$p")
        [[ ":$PATH:" != *":$binDir:"* ]] && export PATH="$binDir:$PATH"
        break
    fi
done

# Ensure log path exists or fallback to null
_TERMIM_LOG="$_TERMIM_HOME/termim.log"
if [[ ! -d "$(dirname "$_TERMIM_LOG" 2>/dev/null)" ]]; then
    _TERMIM_LOG="/dev/null"
fi

# Navigation state
_TERMIM_IDX=0
_TERMIM_CACHE=()
_TERMIM_ORIGINAL_INPUT=""

_TERMIM_PENDING_CMD=""
_TERMIM_PREEXEC_DIR=""

# Pre-execution hook: Mark command as pending
_termim_preexec() {
    _TERMIM_PENDING_CMD="$1"
    _TERMIM_PREEXEC_DIR="$PWD"
    _TERMIM_IDX=0 
    _TERMIM_CACHE=() 
}

# Post-execution hook: Capture exit code and log to termim
_termim_precmd() {
    local exit_status=$?
    if [[ -n "$_TERMIM_PENDING_CMD" ]]; then
        # Penultimate command (the one before the command that just target finished)
        local prev_cmd="$history[$((HISTNO-2))]"
        
        # Log to Termim with explicit CWD and diagnostic logging
        "$_TERMIM_BIN" log "$_TERMIM_PENDING_CMD" --prev "$prev_cmd" --exit "$exit_status" --cwd "$_TERMIM_PREEXEC_DIR" 2>>"$_TERMIM_LOG" &!
        
        _TERMIM_PENDING_CMD=""
        _TERMIM_PREEXEC_DIR=""
    fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _termim_preexec
add-zsh-hook precmd _termim_precmd

# Up arrow: cycle project history (Past)
_termim_up() {
    # First press: Capture input and fetch HISTORY ONLY
    if [[ $_TERMIM_IDX -le 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$BUFFER"
        
        # Capture context for ranking
        local prev_cmd="$(fc -ln -1 | sed 's/^[[:space:]]*//')"
        
        # Termim: Project-aware terminal history and contextual intelligence v1.0.7
# ---------------------------------------------------------------------
        # Fetch strictly history-only results (Recency)
        _TERMIM_CACHE=("${(@f)$($_TERMIM_BIN query --history-only --prev "$prev_cmd" --cwd "$PWD" 2>/dev/null)}")
        _TERMIM_IDX=1
    else
        _TERMIM_IDX=$((_TERMIM_IDX + 1))
    fi
    
    if [[ $_TERMIM_IDX -le ${#_TERMIM_CACHE} ]]; then
        local cmd="${_TERMIM_CACHE[$_TERMIM_IDX]}"
        if [[ "$cmd" != "$BUFFER" ]]; then
            BUFFER="$cmd"
            CURSOR=$#BUFFER
        fi
    else
        # Fallback to standard global history
        zle .up-line-or-history
    fi
}
zle -N _termim_up

# Down arrow: Restore OR Intelligent Prediction (Future)
_termim_down() {
    if [[ $_TERMIM_IDX -gt ${#_TERMIM_CACHE[@]} ]]; then
        # ZONE: GLOBAL HISTORY (Symmetric Hand-off)
        _TERMIM_IDX=$((_TERMIM_IDX - 1))
        zle .down-line-or-history
    elif [[ $_TERMIM_IDX -gt 0 ]]; then
        # ZONE: PROJECT HISTORY
        _TERMIM_IDX=$((_TERMIM_IDX - 1))
        if [[ $_TERMIM_IDX -eq 0 ]]; then
            # Neutral zone (Present)
            BUFFER="$_TERMIM_ORIGINAL_INPUT"
            CURSOR=$#BUFFER
        else
            local cmd="${_TERMIM_CACHE[$_TERMIM_IDX]}"
            BUFFER="$cmd"
            CURSOR=$#BUFFER
        fi
    elif [[ $_TERMIM_IDX -eq 0 && ${BUFFER// /} == "" ]]; then
        # INTELLIGENCE TRIGGER (Future): Trigger prediction on empty prompt
        local prev_cmd="$(fc -ln -1 | sed 's/^[[:space:]]*//')"
        
        # Fetch strictly predictions-only
        _TERMIM_CACHE=("${(@f)$($_TERMIM_BIN query --suggest-only --prev "$prev_cmd" --cwd "$PWD" 2>/dev/null)}")
        
        if [[ ${#_TERMIM_CACHE} -gt 0 ]]; then
            _TERMIM_IDX=-1
            local cmd="${_TERMIM_CACHE[1]}"
            BUFFER="$cmd"
            CURSOR=$#BUFFER
        fi
    elif [[ $_TERMIM_IDX -lt 0 ]]; then
        # Cycling through Predictions (Future)
        local abs_idx=${_TERMIM_IDX#-}
        if [[ $abs_idx -lt ${#_TERMIM_CACHE} ]]; then
            _TERMIM_IDX=$((_TERMIM_IDX - 1))
            abs_idx=${_TERMIM_IDX#-}
            local cmd="${_TERMIM_CACHE[$abs_idx]}"
            BUFFER="$cmd"
            CURSOR=$#BUFFER
        fi
    fi
}
zle -N _termim_down

# Find fzf across platforms
_FZF_BIN="fzf"
if ! command -v fzf &>/dev/null; then
    # Native discovery
    _FZF_BIN=$(whence -p fzf 2>/dev/null)
    
    if [[ -z "$_FZF_BIN" ]]; then
        # Platform-specific searches
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            # Windows/MSYS search 
            local win_where="/c/Windows/System32/where.exe"
            [[ ! -x "$win_where" ]] && win_where="where.exe"
            local win_fzf=$($win_where fzf 2>/dev/null | head -n 1 | tr -d '\r')
            if [[ -z "$win_fzf" ]]; then
                local ps_exe="/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
                [[ ! -x "$ps_exe" ]] && ps_exe="powershell.exe"
                win_fzf=$($ps_exe -NoProfile -Command "(Get-Command fzf -ErrorAction SilentlyContinue).Definition" 2>/dev/null | tr -d '\r')
            fi
            [[ -n "$win_fzf" ]] && _FZF_BIN=$(cygpath -u "$win_fzf" 2>/dev/null)
        fi

        # Common fallback paths
        if [[ -z "$_FZF_BIN" || "$_FZF_BIN" == "fzf" ]]; then
            local fzfPaths=(
                "/usr/local/bin/fzf"
                "/opt/homebrew/bin/fzf"
                "/usr/bin/fzf"
                "/bin/fzf"
                "/c/ProgramData/chocolatey/bin/fzf.exe"
                "$HOME/scoop/shims/fzf.exe"
                "/c/Users/$USER/scoop/shims/fzf.exe"
            )
            for p in "${fzfPaths[@]}"; do
                [[ -f "$p" ]] && _FZF_BIN="$p" && break
            done
        fi
    fi
fi
[[ -z "$_FZF_BIN" ]] && _FZF_BIN="fzf"

# Key bindings
if [[ -o interactive ]]; then
    bindkey '^[[A' _termim_up
    bindkey '^[OA' _termim_up
    bindkey '^[[B' _termim_down
    bindkey '^[OB' _termim_down

    _termim_palette() {
        if ! command -v "$_FZF_BIN" &>/dev/null && [[ ! -f "$_FZF_BIN" ]]; then
            echo -e "\n[termim] fzf not found. Install fzf to use Ctrl+P."
            zle reset-prompt
            return 1
        fi
        local fzf_cmd="$_FZF_BIN"
        if command -v winpty &>/dev/null && "$_FZF_BIN" --version 2>/dev/null | grep -q "windows"; then
            fzf_cmd="winpty $_FZF_BIN"
        fi
        local tmp_hist=$(mktemp)
        "$_TERMIM_BIN" query --cwd "$PWD" 2>/dev/null > "$tmp_hist"
        local selected=$($fzf_cmd \
            --height=40% --reverse --border=rounded \
            --prompt="  termim > " --header="Project History" --no-sort \
            < "$tmp_hist")
        rm -f "$tmp_hist"
        if [[ -n "$selected" ]]; then
            BUFFER="$selected"
            CURSOR=$#BUFFER
            _TERMIM_IDX=0 
            _TERMIM_CACHE=()
        fi
        zle reset-prompt
    }
    zle -N _termim_palette
    bindkey '^P' _termim_palette
    bindkey '^p' _termim_palette
fi
