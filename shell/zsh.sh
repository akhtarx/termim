#!/usr/bin/env zsh
# Termim Zsh Integration
# Compatible with MSYS/Git Bash and macOS

# Find the termim binary
_TERMIM_BIN="termim"
userHome=$(eval echo "~$USER")
possiblePaths="$HOME/.termim/bin/termim $HOME/.termim/bin/termim.exe $userHome/.termim/bin/termim /c/Users/$USER/.termim/bin/termim.exe"
for p in $possiblePaths; do
    if [[ -f "$p" || -x "$p" ]]; then
        _TERMIM_BIN="$p"
        binDir=$(dirname "$p")
        [[ ":$PATH:" != *":$binDir:"* ]] && export PATH="$binDir:$PATH"
        break
    fi
done

# Navigation state
_TERMIM_IDX=0
_TERMIM_CACHE=()
_TERMIM_ORIGINAL_INPUT=""

# Background logging hook
_termim_log() {
    local cmd="$1"
    [[ -z "$cmd" ]] && return
    "$_TERMIM_BIN" log "$cmd" >/dev/null 2>&1 &!
    _TERMIM_IDX=0 
    _TERMIM_CACHE=() 
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _termim_log

# Up arrow: cycle project history
_termim_up() {
    if [[ $_TERMIM_IDX -eq 0 ]]; then
        _TERMIM_ORIGINAL_INPUT="$BUFFER"
        _TERMIM_CACHE=("${(@f)$($_TERMIM_BIN query 2>/dev/null)}")
    fi
    local NEXT_IDX=$((_TERMIM_IDX + 1))
    if [[ $NEXT_IDX -le ${#_TERMIM_CACHE} ]]; then
        local CURR_CMD="${_TERMIM_CACHE[$NEXT_IDX]}"
        if [[ "$CURR_CMD" != "$BUFFER" ]]; then
            _TERMIM_IDX=$NEXT_IDX
            BUFFER="$CURR_CMD"
            CURSOR=$#BUFFER
        else
            _TERMIM_IDX=$NEXT_IDX
        fi
    fi
}
zle -N _termim_up

# Down arrow: restore or cycle next
_termim_down() {
    if [[ $_TERMIM_IDX -le 0 ]]; then
        return
    fi
    local NEXT_IDX=$((_TERMIM_IDX - 1))
    if [[ $NEXT_IDX -eq 0 ]]; then
        if [[ "$BUFFER" != "$_TERMIM_ORIGINAL_INPUT" ]]; then
            BUFFER="$_TERMIM_ORIGINAL_INPUT"
            CURSOR=$#BUFFER
        fi
        _TERMIM_IDX=0
    elif [[ $NEXT_IDX -le ${#_TERMIM_CACHE} ]]; then
        local CURR_CMD="${_TERMIM_CACHE[$NEXT_IDX]}"
        if [[ "$CURR_CMD" != "$BUFFER" ]]; then
            _TERMIM_IDX=$NEXT_IDX
            BUFFER="$CURR_CMD"
            CURSOR=$#BUFFER
        else
            _TERMIM_IDX=$NEXT_IDX
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
        "$_TERMIM_BIN" query 2>/dev/null > "$tmp_hist"
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
