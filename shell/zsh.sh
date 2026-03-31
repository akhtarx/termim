# Termim Zsh Integration (Smart Hybrid Mode)
# Source from ~/.zshrc:  source ~/.termim/shell/zsh.sh

# 1. Update PATH for this session
export PATH="$HOME/.termim/bin:$PATH"

# 2. Native Project Detection (Zero Lag)
_termim_get_root() {
    local current="$PWD"
    local markers=(".git" "package.json" "Cargo.toml" "go.mod" "pyproject.toml" "Makefile" "docker-compose.yml")
    local registry="$HOME/.termim/registry.txt"

    while [[ "$current" != "/" ]]; do
        # Check standard markers
        for m in $markers; do
            if [[ -e "$current/$m" ]]; then
                echo "$current"
                return 0
            fi
        done
        
        # Check Global Registry (Zero-Pollution manual projects)
        if [[ -f "$registry" ]]; then
            if grep -Fxq "$current" "$registry"; then
                echo "$current"
                return 0
            fi
        fi

        current=$(dirname "$current")
    done
    return 1
}

_termim_get_hash() {
    local root=$1
    if [[ -z "$root" ]]; then return 1; fi
    # Normalize to lowercase and remove trailing slash for consistent hashing
    echo -n "${root:l}" | sha256sum | awk '{print $1}'
}

# 3. Ctrl+P: Interactive Palette (Native ZLE)
termim-palette() {
    if ! command -v fzf &>/dev/null; then
        echo "\n[termim] install 'fzf' to use the Ctrl+P palette."
        zle reset-prompt
        return 1
    fi

    local selected
    # Use 'termim query' for history or 'termim suggest' for hybrid
    selected=$(termim query 2>/dev/null | fzf --height=40% --reverse --border=rounded --prompt="  termim > " --header="Project History" --no-sort 2>/dev/null)
    
    if [[ -n "$selected" ]]; then
        # On Zsh, we can either insert into buffer or execute immediately.
        # Here we just insert into the line buffer.
        LBUFFER="$selected"
    fi
    zle reset-prompt
}
zle -N termim-palette
bindkey '^P' termim-palette

# 4. Instant Smart Context Swapping
_termim_native_histfile="$HISTFILE"
_termim_last_hash=""

precmd() {
    local root
    root=$(_termim_get_root)
    local status=$?
    
    if [[ $status -eq 0 ]]; then
        # MODE: Project-Aware History
        local hash=$(_termim_get_hash "$root")
        if [[ "$hash" != "$_termim_last_hash" ]]; then
            _termim_last_hash="$hash"
            
            local projects_dir="$HOME/.termim/projects"
            mkdir -p "$projects_dir"
            local hist_file="$projects_dir/$hash.txt"
            touch "$hist_file"

            # Point Zsh natively to the project file (0ms Lag)
            HISTFILE="$hist_file"
            if [[ -f "$hist_file" ]]; then
                fc -p "$hist_file"
                fc -R "$hist_file"
            fi
        fi
    else
        # MODE: Global Native History (Clean & Silent)
        if [[ -n "$_termim_last_hash" ]]; then
            _termim_last_hash=""
            if [[ -n "$_termim_native_histfile" ]]; then
                # Restore original shell history
                fc -P
                HISTFILE="$_termim_native_histfile"
            fi
        fi
    fi
}
