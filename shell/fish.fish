#!/usr/bin/env fish
# Termim Fish Integration — with Command Intelligence
# Add to ~/.config/fish/config.fish:  source ~/.termim/shell/fish.fish

# 1. Update PATH for this session
if not contains "$HOME/.termim/bin" $PATH
    set -gx PATH "$HOME/.termim/bin" $PATH
end

# 2. Command logging (Direct-to-Disk CLI)
function termim_preexec --on-event fish_preexec
    # Direct CLI logging (Fire-and-forget)
    termim log "$argv[1]" &>/dev/null &
end

# 3. Up-arrow: project history (Native Fish Commandline)
function termim_up
    # Use 'termim query' for project-specific history
    set cmd (termim query 2>/dev/null | head -n 1)
    if test -n "$cmd"
        commandline $cmd
        commandline -C (string length $cmd)
    else
        # Fallback to default behavior
        commandline -f up-or-search
    end
end
bind \e\[A termim_up

# 4. Ctrl+P: Interactive Palette (Requires fzf)
function termim_palette
    if not command -v fzf &>/dev/null
        echo -e "\n[termim] install 'fzf' to use the Ctrl+P palette."
        commandline -f repaint
        return 1
    end

    set selected (termim query 2>/dev/null | fzf \
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
    end
    commandline -f repaint
end
bind \cp termim_palette
