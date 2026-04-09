#!/usr/bin/env bash
# Termim Universal Installer (Zsh + Bash + Fish)
# Usage: curl https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash
# Or locally: bash installer/install.sh

set -e

TERMIM_DIR="$HOME/.termim"
BIN_DIR="$TERMIM_DIR/bin"
SHELL_DIR="$TERMIM_DIR/shell"

echo "=== Termim Universal Unix Installer ==="
echo ""

# 1. Acquire Binary
echo "[1/4] Acquiring Termim binary..."
BINARY_PATH=""

# Mode A: Pre-compiled binary exists in current folder
if [ -f "./termim" ]; then
    BINARY_PATH="./termim"
    echo "  ✓ Using local termim binary"
# Mode B: Build from source if Cargo is available
elif command -v cargo &>/dev/null; then
    echo "  Cargo found. Building from source (release)..."
    if cargo build --release; then
        BINARY_PATH="target/release/termim"
        echo "  ✓ Built successfully"
    else
        echo "  ! WARNING: Build failed. Trying fallback..."
    fi
fi

# Mode C: Fallback to GitHub Release download
if [ -z "$BINARY_PATH" ]; then
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64) T_ARCH="x86_64" ;;
        aarch64|arm64) T_ARCH="aarch64" ;;
        *) T_ARCH="x86_64" ;;
    esac

    case "$OS" in
        linux) T_OS="linux" ;;
        darwin) T_OS="macos" ;;
        *) echo "  ! Unsupported OS for automatic download. Please install Rust and build from source."; exit 1 ;;
    esac

    FILE_NAME="termim-$T_OS-$T_ARCH"
    DOWNLOAD_URL="https://github.com/akhtarx/termim/releases/latest/download/$FILE_NAME"
    
    echo "  Safe Mode: Downloading pre-compiled binary ($FILE_NAME) from GitHub..."
    if curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/termim"; then
        BINARY_PATH="$BIN_DIR/termim"
        chmod +x "$BINARY_PATH"
        echo "  ✓ Downloaded latest release"
    else
        echo "  ! ERROR: Could not build or download Termim. Please ensure you have an internet connection or Rust installed."
        exit 1
    fi
fi

# 2. Create directory structure
echo "[2/4] Creating $TERMIM_DIR..."
mkdir -p "$BIN_DIR"
mkdir -p "$SHELL_DIR"
echo "  ✓ Created"

# 2.5 Install fzf (Dynamic Latest)
echo "[2.5/4] Bundling fzf for history palette..."
if ! command -v fzf &>/dev/null && [ ! -f "$BIN_DIR/fzf" ]; then
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    # Map architecture names
    case "$ARCH" in
        x86_64) FZF_ARCH="amd64" ;;
        aarch64|arm64) FZF_ARCH="arm64" ;;
        *) FZF_ARCH="amd64" ;;
    esac

    echo "  fzf not found. Fetching latest version from GitHub..."
    # Attempt to get latest version via GitHub API
    FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | grep "tag_name" | cut -d '"' -f 4 | tr -d 'v')
    
    if [ -z "$FZF_VERSION" ]; then
        FZF_VERSION="0.56.0" # Hard fallback if API fails
        echo "  ! WARNING: Could not fetch latest version, falling back to v$FZF_VERSION"
    else
        echo "  ✓ Latest version found: v$FZF_VERSION ($FZF_ARCH)"
    fi

    FZF_URL=""
    if [ "$OS" == "linux" ]; then
        FZF_URL="https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_$FZF_ARCH.tar.gz"
    elif [ "$OS" == "darwin" ]; then
        FZF_URL="https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-darwin_$FZF_ARCH.tar.gz"
    fi

    if [ -n "$FZF_URL" ]; then
        echo "  Downloading for $OS/$FZF_ARCH..."
        if curl -fsSL "$FZF_URL" -o "$BIN_DIR/fzf.tar.gz"; then
            tar -xzf "$BIN_DIR/fzf.tar.gz" -C "$BIN_DIR" fzf
            rm "$BIN_DIR/fzf.tar.gz"
            chmod +x "$BIN_DIR/fzf"
            echo "  ✓ fzf installed to $BIN_DIR"
        else
            echo "  ! WARNING: Failed to download fzf. You may need to install it manually."
        fi
    fi
else
    echo "  ✓ fzf already available"
fi

# 3. Install binary and shell scripts
echo "[3/4] Installing binary and shell suite..."
if [ "$BINARY_PATH" != "$BIN_DIR/termim" ]; then
    cp "$BINARY_PATH" "$BIN_DIR/termim"
    chmod +x "$BIN_DIR/termim"
fi
cp shell/bash.sh "$SHELL_DIR/bash.sh"
cp shell/zsh.sh "$SHELL_DIR/zsh.sh"
cp shell/fish.fish "$SHELL_DIR/fish.fish"
echo "  ✓ Installed to $TERMIM_DIR"

# 4. Configure shell profiles
echo "[4/4] Configuring shell profiles..."
export_path="export PATH=\"\$HOME/.termim/bin:\$PATH\""

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

# Fish
if [ -d "$HOME/.config/fish" ]; then
    fish_config="$HOME/.config/fish/config.fish"
    mkdir -p "$(dirname "$fish_config")"
    touch "$fish_config"
    
    fish_path="set -gx PATH \"\$HOME/.termim/bin\" \$PATH"
    fish_source="source ~/.termim/shell/fish.fish"
    
    grep -q "termim/bin" "$fish_config" || echo "$fish_path" >> "$fish_config"
    grep -q "termim/shell" "$fish_config" || echo "$fish_source" >> "$fish_config"
    echo "  ✓ Updated $fish_config"
fi

echo ""
echo "=== Termim Universal Installation Complete! ==="
echo ""
echo "Note: Restart your shell or run 'source ~/.your_shell_rc' to activate."
