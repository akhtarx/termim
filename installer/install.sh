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
QUIET=false
FORCE=false
SKIP_FZF=false

for arg in "$@"; do
    case $arg in
        --build) DO_BUILD=true ;;
        --quiet|-q) QUIET=true ;;
        --force|-f) FORCE=true ;;
        --no-fzf) SKIP_FZF=true ;;
        --version=*) VERSION="${arg#*=}" ;;
    esac
done

if [ "$QUIET" = true ]; then
    exec > /dev/null
fi

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
    if curl -fsSL "$DOWNLOAD_URL" -o "$BIN_DIR/$FILE_NAME"; then
        chmod +x "$BIN_DIR/$FILE_NAME"
        
        # Checksum Verification
        info "Verifying checksum..."
        if curl -fsSL "${DOWNLOAD_URL}.sha256" -o "$BIN_DIR/$FILE_NAME.sha256"; then
            if command -v sha256sum &>/dev/null; then
                (cd "$BIN_DIR" && sha256sum -c "$FILE_NAME.sha256") || error "Checksum mismatch!"
            elif command -v shasum &>/dev/null; then
                (cd "$BIN_DIR" && shasum -a 256 -c "$FILE_NAME.sha256") || error "Checksum mismatch!"
            else
                warn "shasum/sha256sum not found. Skipping verification."
            fi
            rm "$BIN_DIR/$FILE_NAME.sha256"
            success "Checksum verified."
        else
            warn "No checksum file found on server. Skipping verification."
        fi
        
        mv "$BIN_DIR/$FILE_NAME" "$BIN_DIR/termim"
        success "Termim binary installed to $BIN_DIR/termim"

        # Programmatic Security Bypass: Remove quarantine bit on macOS
        if [ "$OS" = "darwin" ] && command -v xattr &>/dev/null; then
            info "Unblocking binary for macOS execution..."
            xattr -d com.apple.quarantine "$BIN_DIR/termim" 2>/dev/null || true
        fi
    else
        error "Download failed. Please check your internet connection or GitHub status. To build from source, clone the repository and run with --build."
    fi
fi

# 3. fzf Check
if [ "$SKIP_FZF" = true ]; then
    info "Skipping fzf check as requested."
elif command -v fzf &>/dev/null; then
    success "fzf found in PATH."
elif [ -f "$BIN_DIR/fzf" ]; then
    success "fzf found in Termim bin directory."
else
    warn "fzf not found. Termim requires fzf for the interactive palette (Ctrl+P)."
    INSTALL_FZF=false
    if [ "$FORCE" = true ]; then
        INSTALL_FZF=true
    else
        read -p "  Would you like to install a local copy of fzf into $BIN_DIR? [y/N] " -n 1 -r < /dev/tty
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_FZF=true
        fi
    fi

    if [ "$INSTALL_FZF" = true ]; then
        info "Installing local fzf..."
        F_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
        F_ARCH=$(uname -m)
        case "$F_ARCH" in
            x86_64) F_ARCH_MAPPED="amd64" ;;
            aarch64|arm64) F_ARCH_MAPPED="arm64" ;;
            *) F_ARCH_MAPPED="amd64" ;;
        esac
        
        # Fetch latest version from GitHub API
        FZF_VER=$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest | grep "tag_name" | cut -d '"' -f 4 | tr -d 'v')
        [ -z "$FZF_VER" ] && FZF_VER="0.56.0"
        
        FZF_FILE="fzf-$FZF_VER-${F_OS}_$F_ARCH_MAPPED.tar.gz"
        FZF_URL="https://github.com/junegunn/fzf/releases/download/v$FZF_VER/$FZF_FILE"
        
        if curl -fsSL "$FZF_URL" -o "$BIN_DIR/fzf.tar.gz"; then
            tar -xzf "$BIN_DIR/fzf.tar.gz" -C "$BIN_DIR" fzf
            rm "$BIN_DIR/fzf.tar.gz"
            chmod +x "$BIN_DIR/fzf"
            if [ "$OS" = "darwin" ] && command -v xattr &>/dev/null; then
                xattr -d com.apple.quarantine "$BIN_DIR/fzf" 2>/dev/null || true
            fi
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

# Detect active shell from $SHELL env var (more reliable when running via pipe)
case "$SHELL" in
    */zsh)
        echo -e "  ${BLUE}source ~/.zshrc${NC}"
        ;;
    */bash)
        echo -e "  ${BLUE}source ~/.bashrc${NC}"
        ;;
    */fish)
        echo -e "  ${BLUE}source ~/.config/fish/config.fish${NC}"
        ;;
    *)
        # Fallback to shell-specific detection if SHELL is unset
        if [ -n "$ZSH_VERSION" ]; then
            echo -e "  ${BLUE}source ~/.zshrc${NC}"
        else
            echo -e "  ${BLUE}source ~/.bashrc${NC}"
        fi
        ;;
esac
echo -e "\nOr just open a new terminal tab. Enjoy!"
