# Termim Bash Integration — with Command Intelligence
# Source from ~/.bashrc:  source ~/.termim/shell/bash.sh

# 1. Update PATH for this session
export PATH="$HOME/.termim/bin:$PATH"

# 2. Command logging (Direct-to-Disk CLI)
_termim_log() {
    local last_cmd
    # Get the last command from history
    last_cmd=$(HISTTIMEFORMAT='' history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
    
    if [[ -n "$last_cmd" && "$last_cmd" != "$_TERMIM_LAST_CMD" ]]; then
        # Direct CLI logging (Fire-and-forget)
        termim log "$last_cmd" 2>/dev/null &
        _TERMIM_LAST_CMD="$last_cmd"
    fi
}

# Attach to PROMPT_COMMAND for automatic logging
if [[ "$PROMPT_COMMAND" != *"_termim_log"* ]]; then
    PROMPT_COMMAND="_termim_log; $PROMPT_COMMAND"
fi

# 3. Up-arrow: project history (Native Readline)
_termim_up() {
    local cmd
    # Use 'termim query' for project-specific history
    cmd=$(termim query 2>/dev/null | head -n 1)
    if [[ -n "$cmd" ]]; then
        READLINE_LINE="$cmd"
        READLINE_POINT=${#cmd}
    fi
}
# Bind for standard Bash (\e[A) and MinTTY/GitBash (\eOA)
bind -x '"\e[A": _termim_up'
bind -x '"\eOA": _termim_up'

# 4. Ctrl+P: Interactive Palette (Requires fzf)
_termim_palette() {
    if ! command -v fzf &>/dev/null; then
        echo -e "\n[termim] install 'fzf' to use the Ctrl+P palette."
        return 1
    fi

    local selected
    # Use 'termim query' for project-specific history
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
    fi
}
bind -x '"\C-p": _termim_palette'
