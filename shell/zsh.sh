# Termim Zsh Integration — with Stateful Native Mastery
# Mastery Edition: Global Gold Standard (Resilient & Silky Smooth) v1.0.1
# Source from ~/.zshrc:  source ~/.termim/shell/zsh.sh

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
_TERMIM_CACHE=()
_TERMIM_ORIGINAL_INPUT=""

# 3. Silent Command Logging (Direct-to-Disk CLI)
_termim_log() {
    # Fail-Safe: Check for binary existence
    [[ -z "$_TERMIM_BIN" ]] && return
    
    local last_cmd
    last_cmd=$(history | tail -n 1 | sed 's/^[ ]*[0-9]*[ ]*//')
    
    if [[ -n "$last_cmd" && "$last_cmd" != "$_TERMIM_LAST_CMD" ]]; then
        # Silent Background Logging (Maverick Subshell Trick)
        ("$_TERMIM_BIN" log "$last_cmd" &>/dev/null &) 
        _TERMIM_LAST_CMD="$last_cmd"
        _TERMIM_IDX=0 
        _TERMIM_CACHE=() 
    fi
}

# Attach to Zsh preexec hook for automatic logging
autoload -Uz add-zsh-hook
add-zsh-hook preexec _termim_log

# 4. Stateful Up-arrow: project history (Native ZLE Widget)
_termim_up() {
    # Fail-Safe check
    [[ -z "$_TERMIM_BIN" ]] && zle .up-line-or-history && return

    # 1. Initialize Cache on first press (Industrial Latency Fix)
    if [[ $_TERMIM_IDX -eq 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$BUFFER"
        # Load history into Zsh array (split by newline)
        _TERMIM_CACHE=(${(f)"$($_TERMIM_BIN query 2>/dev/null)"})
    fi

    # 2. Native Fallback if no project history
    if [[ ${#_TERMIM_CACHE} -eq 0 ]]; then
        zle .up-line-or-history
        return
    fi

    local next_idx=$((_TERMIM_IDX + 1))
    
    # 3. Access In-Memory Array for 0ms recall
    if [[ $next_idx -le ${#_TERMIM_CACHE} ]]; then
        local cmd="${_TERMIM_CACHE[$next_idx]}"
        # Anti-Flicker: Only update if different
        if [[ "$cmd" != "$BUFFER" ]]; then
            _TERMIM_IDX=$next_idx
            BUFFER="$cmd"
            CURSOR=$#BUFFER
        else
            _TERMIM_IDX=$next_idx
        fi
    fi
}
zle -N _termim_up

# 5. Stateful Down-arrow: project history
_termim_down() {
    if [[ $_TERMIM_IDX -le 0 ]]; then
        zle .down-line-or-history
        return
    fi

    local next_idx=$((_TERMIM_IDX - 1))
    
    if [[ $next_idx -eq 0 ]]; then
        # Anti-Flicker: Only update if different
        if [[ "$BUFFER" != "$_TERMIM_ORIGINAL_INPUT" ]]; then
            BUFFER="$_TERMIM_ORIGINAL_INPUT"
            CURSOR=$#BUFFER
        fi
        _TERMIM_IDX=0
    elif [[ $next_idx -le ${#_TERMIM_CACHE} ]]; then
        local cmd="${_TERMIM_CACHE[$next_idx]}"
        if [[ "$cmd" != "$BUFFER" ]]; then
            _TERMIM_IDX=$next_idx
            BUFFER="$cmd"
            CURSOR=$#BUFFER
        else
            _TERMIM_IDX=$next_idx
        fi
    fi
}
zle -N _termim_down

# 6. Bind standard Zsh escape sequences
bindkey '^[[A' _termim_up
bindkey '^[OA' _termim_up
bindkey '^[[B' _termim_down
bindkey '^[OB' _termim_down

# 7. Ctrl+P: Interactive Palette (Requires fzf)
_termim_palette() {
    if ! command -v fzf &>/dev/null; then
        echo -e "\n[termim] install 'fzf' to use the Ctrl+P palette."
        zle reset-prompt
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
        BUFFER="$selected"
        CURSOR=$#BUFFER
        _TERMIM_IDX=0 
        _TERMIM_CACHE=()
    fi
    zle reset-prompt
}
zle -N _termim_palette
bindkey '^P' _termim_palette
