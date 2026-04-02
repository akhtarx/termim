#!/usr/bin/env bash
# Termim Universal Installer (Zsh + Bash + Fish)
# Usage: curl https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash
# Or locally: bash installer/install.sh

set -e

TERMIM_DIR="$HOME/.termim"
BIN_DIR="$TERMIM_DIR/bin"
SHELL_DIR="$TERMIM_DIR/shell"

echo "=== Termim Unix Installer (Pure CLI) v1.0.1 ==="
echo "Welcome to the AkhtarX Labs laboratory."
echo ""

# 1. Build release binary
echo "[1/4] Building Termim..."
cargo build --release
echo "  ✓ Built"

# 2. Create directory structure
echo "[2/4] Creating $TERMIM_DIR..."
mkdir -p "$BIN_DIR"
mkdir -p "$SHELL_DIR"
echo "  ✓ Created"

# 3. Install binary and shell masters
echo "[3/4] Installing binary and shell suite..."
cp target/release/termim "$BIN_DIR/termim"
chmod +x "$BIN_DIR/termim"
cp shell/bash.sh "$SHELL_DIR/bash.sh"
cp shell/zsh.sh "$SHELL_DIR/zsh.sh"
cp shell/fish.fish "$SHELL_DIR/fish.fish"
echo "  ✓ Installed to $TERMIM_DIR"

# 4. Aggressive Shell Configuration
echo "[4/4] Configuring shell profiles..."
export_path='export PATH="$HOME/.termim/bin:$PATH"'

# Bash & Zsh
for profile in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.profile"; do
    if [ -f "$profile" ]; then
        shell_name=$(basename "$profile" | sed 's/^\.//;s/rc$//')
        source_line="source ~/.termim/shell/$shell_name.sh"
        
        # Ensure PATH
        grep -qxF "$export_path" "$profile" || echo "$export_path" >> "$profile"
        # Ensure Source
        grep -q "termim/shell" "$profile" || echo "$source_line" >> "$profile"
        echo "  ✓ Updated $profile"
    fi
done

# Fish (Modernized Configuration)
if [ -d "$HOME/.config/fish" ]; then
    mkdir -p "$HOME/.config/fish"
    fish_config="$HOME/.config/fish/config.fish"
    touch "$fish_config"
    
    # Fish PATH (Native fish command)
    fish_path="set -gx PATH \"\$HOME/.termim/bin\" \$PATH"
    fish_source="source ~/.termim/shell/fish.fish"
    
    grep -q "termim/bin" "$fish_config" || echo "$fish_path" >> "$fish_config"
    grep -q "termim/shell" "$fish_config" || echo "$fish_source" >> "$fish_config"
    echo "  ✓ Updated $fish_config"
fi

echo ""
echo "=== Termim v1.0.0 Universal Installation Complete! ==="
echo ""
echo "Note: Restart your shell or run 'source ~/.your_shell_rc' to activate."
