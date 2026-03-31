#!/usr/bin/env bash
# Termim Installer (Unix/macOS/WSL)
# Usage: curl https://termim.dev/install.sh | bash
# Or locally: bash installer/install.sh

set -e

TERMIM_DIR="$HOME/.termim"
BIN_DIR="$TERMIM_DIR/bin"

echo "=== Termim Installer (Pure CLI v1.0.0) ==="
echo ""

# 1. Build release binary
echo "[1/4] Building Termim..."
cargo build --release
echo "  ✓ Built"

# 2. Create ~/.termim directory structure
echo "[2/4] Creating ~/.termim..."
mkdir -p "$BIN_DIR"
mkdir -p "$TERMIM_DIR/shell"
echo "  ✓ Created $TERMIM_DIR"

# 3. Install binary
echo "[3/4] Installing binary..."
cp target/release/termim "$BIN_DIR/termim"
chmod +x "$BIN_DIR/termim"
echo "  ✓ Installed termim to $BIN_DIR"

# 4. Install shell plugins
echo "[4/4] Installing shell plugins..."
cp shell/zsh.sh "$TERMIM_DIR/shell/zsh.sh"
cp shell/bash.sh "$TERMIM_DIR/shell/bash.sh"
echo "  ✓ Plugins installed"

# 5. Modify shell config files
echo "[5/5] Configuring your shell..."
export_path='export PATH="$HOME/.termim/bin:$PATH"'
source_zsh='source ~/.termim/shell/zsh.sh'
source_bash='source ~/.termim/shell/bash.sh'

if [ -f "$HOME/.zshrc" ]; then
    grep -qxF "$export_path" "$HOME/.zshrc" || echo "$export_path" >> "$HOME/.zshrc"
    grep -qxF "$source_zsh"  "$HOME/.zshrc" || echo "$source_zsh"  >> "$HOME/.zshrc"
    echo "  ✓ Updated ~/.zshrc"
fi

if [ -f "$HOME/.bashrc" ]; then
    grep -qxF "$export_path" "$HOME/.bashrc" || echo "$export_path" >> "$HOME/.bashrc"
    grep -qxF "$source_bash" "$HOME/.bashrc" || echo "$source_bash" >> "$HOME/.bashrc"
    echo "  ✓ Updated ~/.bashrc"
fi

echo ""
echo "=== Termim v1.0.0 installed successfully! ==="
echo ""
echo "Restart your shell or run:"
echo "  source ~/.zshrc    # for Zsh"
echo "  source ~/.bashrc   # for Bash"
echo ""
echo "Test it:"
echo "  termim query"
echo "  termim stats"
echo ""
echo "Note: Binary is at $BIN_DIR/termim"
