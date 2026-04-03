#!/bin/bash
# Termim Universal Unix Uninstaller (Zsh + Bash + Fish)
# Usage: bash installer/uninstall.sh

echo "=== Termim Universal Unix Uninstaller (Industry-Grade) ==="
echo ""

TERMIM_DIR="$HOME/.termim"

# 1. Shell Profile Cleanup (Surgical Removal)
echo "[1/3] Surgically Removing Shell Integrations..."

# Clean Bash & Zsh
for profile in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$profile" ]; then
        # Pure Surgical Removal using sed
        sed -i '/termim\/shell/d' "$profile"
        sed -i '/termim\/bin/d' "$profile"
        echo "  OK: $profile cleaned"
    fi
done

# Clean Fish
if [ -d "$HOME/.config/fish" ]; then
    fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
        sed -i '/termim\/shell/d' "$fish_config"
        sed -i '/termim\/bin/d' "$fish_config"
        echo "  OK: $fish_config cleaned"
    fi
fi

# 2. Final Purge
echo "[2/3] Deleting $TERMIM_DIR..."
if [ -d "$TERMIM_DIR" ]; then
    rm -rf "$TERMIM_DIR"
    echo "  OK: $TERMIM_DIR deleted"
fi

echo ""
echo "=== Termim v1.0.1 successfully removed! ==="
echo ""
echo "Note: You can close this terminal window to finalize the changes."
