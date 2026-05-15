#!/usr/bin/env bash
# Termim Universal Installer (Unix/macOS)
# Usage: curl -fsSL https://raw.githubusercontent.com/akhtarx/termim/main/installer/install.sh | bash
#
# Principles:
# 1. Prefer prebuilt binaries for zero-dependency install.
# 2. Build from source only if --build is passed.
# 3. Idempotent shell configuration.
# 4. Minimal interference with existing tools (fzf).

set -e

# --- Configuration ---
TERMIM_DIR="${TERMIM_DIR:-$HOME/.termim}"
BIN_DIR="$TERMIM_DIR/bin"
SHELL_DIR="$TERMIM_DIR/shell"
REPO="akhtarx/termim"
VERSION="latest"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[info]${NC} $1"; }
success() { echo -e "${GREEN}[success]${NC} $1"; }
warn() { echo -e "${YELLOW}[warn]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} $1"; exit 1; }

# --- Arguments ---
DO_BUILD=false
for arg in "$@"; do
    case $arg in
        --build) DO_BUILD=true ;;
        --version=*) VERSION="${arg#*=}" ;;
    esac
done

echo -e "${BLUE}=== Termim: Directory & Context-Aware History Installer ===${NC}\n"

# 1. Prerequisites
info "Verifying environment..."
mkdir -p "$BIN_DIR" "$SHELL_DIR"

# 2. Acquire Binary
if [ "$DO_BUILD" = true ]; then
    info "Building from source as requested..."
    if ! command -v cargo &>/dev/null; then
        error "Cargo/Rust not found. Install Rust or run without --build to use prebuilt binaries."
    fi
    if cargo build --release; then
        cp target/release/termim "$BIN_DIR/termim"
        success "Built and installed to $BIN_DIR/termim"
    else
        error "Build failed."
    fi
else
    # Automatic download logic
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64) T_ARCH="x86_64" ;;
        aarch64|arm64) T_ARCH="aarch64" ;;
        *) error "Unsupported architecture: $ARCH. Please use --build." ;;
    esac

    case "$OS" in
        linux) T_OS="linux" ;;
        darwin) T_OS="macos" ;;
        *) error "Unsupported OS: $OS. Please use --build." ;;
    esac

    FILE_NAME="termim-$T_OS-$T_ARCH"
    if [ "$VERSION" = "latest" ]; then
        DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/$FILE_NAME"
    else
        DOWNLOAD_URL="https://github.com/$REPO/releases/download/v$VERSION/$FILE_NAME"
    fi

    info "Downloading $VERSION prebuilt binary ($T_OS/$T_ARCH)..."
    if curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/termim"; then
        chmod +x "$BIN_DIR/termim"
        
        # Checksum Verification
        info "Verifying checksum..."
        if curl -fsSL "${DOWNLOAD_URL}.sha256" -o "$BIN_DIR/termim.sha256"; then
            if command -v sha256sum &>/dev/null; then
                (cd "$BIN_DIR" && sha256sum -c termim.sha256) || error "Checksum mismatch!"
            elif command -v shasum &>/dev/null; then
                (cd "$BIN_DIR" && shasum -a 256 -c termim.sha256) || error "Checksum mismatch!"
            else
                warn "shasum/sha256sum not found. Skipping verification."
            fi
            rm "$BIN_DIR/termim.sha256"
            success "Checksum verified."
        else
            warn "No checksum file found on server. Skipping verification."
        fi
        
        success "Termim binary installed to $BIN_DIR/termim"
    else
        warn "Download failed. Attempting build from source..."
        if command -v cargo &>/dev/null; then
             cargo build --release && cp target/release/termim "$BIN_DIR/termim" && success "Built from source."
        else
             error "Prebuilt binary download failed and Cargo is not installed."
        fi
    fi
fi

# 3. fzf Check
info "Checking for fzf (required for palette)..."
if command -v fzf &>/dev/null; then
    success "fzf found in PATH."
elif [ -f "$BIN_DIR/fzf" ]; then
    success "fzf found in Termim bin directory."
else
    warn "fzf not found. Termim requires fzf for the interactive palette (Ctrl+P)."
    read -p "  Would you like to install a local copy of fzf into $BIN_DIR? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing local fzf..."
        F_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        F_ARCH=$(uname -m)
        case "$F_ARCH" in
            x86_64) F_ARCH_MAPPED="amd64" ;;
            aarch64|arm64) F_ARCH_MAPPED="arm64" ;;
            *) F_ARCH_MAPPED="amd64" ;;
        esac
        
        # We'll use a fixed version for stability in the installer
        FZF_VER="0.56.0"
        FZF_FILE="fzf-$FZF_VER-${F_OS}_$F_ARCH_MAPPED.tar.gz"
        FZF_URL="https://github.com/junegunn/fzf/releases/download/v$FZF_VER/$FZF_FILE"
        
        if curl -fsSL "$FZF_URL" -o "$BIN_DIR/fzf.tar.gz"; then
            tar -xzf "$BIN_DIR/fzf.tar.gz" -C "$BIN_DIR" fzf
            rm "$BIN_DIR/fzf.tar.gz"
            chmod +x "$BIN_DIR/fzf"
            success "Local fzf installed."
        else
            warn "fzf download failed. Please install it manually: https://github.com/junegunn/fzf"
        fi
    fi
fi

# 4. Install Shell Suites
info "Installing shell integration scripts..."
# If running via curl, we might not have the shell folder locally. 
# We should try to download them if they aren't here.
if [ -d "./shell" ]; then
    cp shell/*.sh "$SHELL_DIR/" 2>/dev/null || true
    cp shell/*.fish "$SHELL_DIR/" 2>/dev/null || true
else
    info "Downloading integration scripts from main branch..."
    for s in bash.sh zsh.sh fish.fish; do
        curl -fsSL "https://raw.githubusercontent.com/$REPO/main/shell/$s" -o "$SHELL_DIR/$s"
    done
fi
success "Scripts installed to $SHELL_DIR"

# 5. Idempotent Shell Config
configure_shell() {
    local rc_file="$1"
    local shell_type="$2"
    local init_block
    
    if [ ! -f "$rc_file" ]; then return; fi
    
    info "Configuring $rc_file..."
    
    if [ "$shell_type" = "fish" ]; then
        init_block="# >>> termim initialize >>>
if test -f $SHELL_DIR/fish.fish
    set -gx PATH \"$BIN_DIR\" \$PATH
    source $SHELL_DIR/fish.fish
end
# <<< termim initialize <<<"
    else
        init_block="# >>> termim initialize >>>
if [ -f \"$SHELL_DIR/$shell_type.sh\" ]; then
    export PATH=\"$BIN_DIR:\$PATH\"
    source \"$SHELL_DIR/$shell_type.sh\"
fi
# <<< termim initialize <<<"
    fi

    # Remove existing block if present
    sed -i.bak '/# >>> termim initialize >>>/,/# <<< termim initialize <<</d' "$rc_file" && rm -f "${rc_file}.bak"
    
    # Append new block
    echo -e "\n$init_block" >> "$rc_file"
    success "Updated $rc_file"
}

if [ -f "$HOME/.bashrc" ]; then configure_shell "$HOME/.bashrc" "bash"; fi
if [ -f "$HOME/.zshrc" ]; then configure_shell "$HOME/.zshrc" "zsh"; fi
if [ -d "$HOME/.config/fish" ]; then 
    mkdir -p "$HOME/.config/fish"
    touch "$HOME/.config/fish/config.fish"
    configure_shell "$HOME/.config/fish/config.fish" "fish"
fi

echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
echo -e "${YELLOW}Important:${NC} To start using Termim in this window, run:"
if [ -n "$BASH_VERSION" ]; then
    echo -e "  ${BLUE}source ~/.bashrc${NC}"
elif [ -n "$ZSH_VERSION" ]; then
    echo -e "  ${BLUE}source ~/.zshrc${NC}"
else
    echo -e "  ${BLUE}source ~/.$(basename $SHELL)rc${NC}"
fi
echo -e "\nOr just open a new terminal tab. Enjoy!"
