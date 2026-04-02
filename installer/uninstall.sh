#!/bin/bash
# Termim Unix Uninstaller (Zsh + Bash + Fish)
# Usage: bash installer/uninstall.sh

echo "=== Termim Unix Uninstaller (Industry-Grade) ==="
echo ""

TERMIM_DIR="$HOME/.termim"

# 1. Shell Profile Cleanup
echo "[1/3] Cleaning Shell Integrations..."
for profile in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$profile" ]; then
        # Remove Termim source lines
        sed -i '/termim\/shell/d' "$profile"
        echo "  OK: $profile cleaned"
    fi
done

# 2. Fish Cleanup
if [ -d "$HOME/.config/fish" ]; then
    fish_config="$HOME/.config/fish/config.fish"
    if [ -f "$fish_config" ]; then
        sed -i '/termim\/shell/d' "$fish_config"
        echo "  OK: $fish_config cleaned"
    fi
fi

# 3. Final Purge
echo "[2/3] Deleting $TERMIM_DIR..."
if [ -d "$TERMIM_DIR" ]; then
    rm -rf "$TERMIM_DIR"
    echo "  OK: $TERMIM_DIR deleted"
fi

echo ""
echo "=== Termim v1.0.0 successfully removed! ==="
echo ""
echo "Note: You can close this terminal window to finalize the changes."
