#!/usr/bin/env bash

# Dotfiles Installation Script
# Supports: macOS (Homebrew) and Arch Linux (pacman/yay)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$HOME/.dotfiles_install.log"

# Flags
DRY_RUN=false
VERBOSE=false

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    
    case "$level" in
        INFO)
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "${BLUE}ℹ${NC} ${message}"
            fi
            ;;
        SUCCESS)
            echo -e "${GREEN}✓${NC} ${message}"
            ;;
        WARN)
            echo -e "${YELLOW}⚠${NC} ${message}"
            ;;
        ERROR)
            echo -e "${RED}✗${NC} ${message}" >&2
            ;;
    esac
}

# Print with color support
print_color() {
    echo -e "$@"
}

# Print banner
banner() {
    echo ""
    print_color "${BLUE}"
    cat << 'EOF'
▄ ▄▖▄▖▄▖▄▖▖ ▄▖▄▖
▌▌▌▌▐ ▙▖▐ ▌ ▙▖▚ 
▙▘▙▌▐ ▌ ▟▖▙▖▙▖▄▌
                
EOF
    print_color "${NC}"
    echo ""
}

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Install dotfiles dependencies for macOS or Arch Linux.

OPTIONS:
    -h, --help         Show this help message
    -n, --dry-run      Show what would be installed without doing it
    -v, --verbose      Show detailed output

EXAMPLES:
    ./install.sh                  # Install all dependencies
    ./install.sh --dry-run        # Preview installation
    ./install.sh --verbose        # Detailed output

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -n|--dry-run)
            DRY_RUN=true
            VERBOSE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            print_color "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

# Install Homebrew (macOS)
install_homebrew() {
    if command -v brew &>/dev/null; then
        log "INFO" "Homebrew already installed"
        return 0
    fi
    
    log "INFO" "Installing Homebrew..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install Homebrew"
        return 0
    fi
    
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log "SUCCESS" "Homebrew installed"
}

# Install packages via Homebrew (macOS)
install_macos_packages() {
    log "INFO" "Installing macOS packages via Homebrew..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would run: brew bundle --file=$SCRIPT_DIR/Brewfile"
        return 0
    fi
    
    brew bundle --file="$SCRIPT_DIR/Brewfile"
    log "SUCCESS" "macOS packages installed"
}

# Install yay (Arch)
install_yay() {
    if command -v yay &>/dev/null; then
        log "INFO" "yay already installed"
        return 0
    fi
    
    log "INFO" "Installing yay AUR helper..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install yay"
        return 0
    fi
    
    sudo pacman -S --needed --noconfirm base-devel git
    
    local temp_dir="/tmp/yay-install-$$"
    git clone https://aur.archlinux.org/yay.git "$temp_dir"
    cd "$temp_dir"
    makepkg -si --noconfirm
    cd - > /dev/null
    rm -rf "$temp_dir"
    
    log "SUCCESS" "yay installed"
}

# Install packages via yay/pacman (Arch)
install_arch_packages() {
    log "INFO" "Installing Arch Linux packages..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install packages from packages-arch.txt"
        log "INFO" "[DRY RUN] Would install AUR packages from packages-aur.txt"
        return 0
    fi
    
    # Install official repo packages
    log "INFO" "Installing official repository packages..."
    yay -S --needed --noconfirm - < "$SCRIPT_DIR/packages-arch.txt"
    
    # Install AUR packages
    log "INFO" "Installing AUR packages..."
    yay -S --needed --noconfirm - < "$SCRIPT_DIR/packages-aur.txt"
    
    log "SUCCESS" "Arch Linux packages installed"
}

# Install oh-my-zsh
install_ohmyzsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log "INFO" "oh-my-zsh already installed"
        return 0
    fi
    
    log "INFO" "Installing oh-my-zsh..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install oh-my-zsh"
        return 0
    fi
    
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log "SUCCESS" "oh-my-zsh installed"
}

# Install powerlevel10k theme
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [[ -d "$p10k_dir" ]]; then
        log "INFO" "powerlevel10k already installed"
        return 0
    fi
    
    log "INFO" "Installing powerlevel10k theme..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install powerlevel10k"
        return 0
    fi
    
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    log "SUCCESS" "powerlevel10k installed"
}

# Install mise tools
install_mise_tools() {
    if ! command -v mise &>/dev/null; then
        log "WARN" "mise not found. It should have been installed via package manager."
        log "INFO" "Installing mise manually..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "[DRY RUN] Would install mise"
            return 0
        fi
        
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    log "INFO" "Installing mise tools from .mise.toml..."
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would run: mise install"
        return 0
    fi
    
    mise install
    log "SUCCESS" "mise tools installed"
}

# Install gh extensions
install_gh_extensions() {
    if ! command -v gh &>/dev/null; then
        log "WARN" "gh CLI not found, skipping extension installation"
        return 0
    fi
    
    log "INFO" "Installing gh extensions..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "[DRY RUN] Would install gh extensions"
        return 0
    fi
    
    # Array of extensions to install
    local extensions=(
        "dlvhdr/gh-dash"
        # Add more extensions here in the future
    )
    
    for ext in "${extensions[@]}"; do
        local ext_name="${ext##*/}"  # Extract name after /
        
        if gh extension list | grep -q "$ext"; then
            log "INFO" "gh extension '$ext_name' already installed"
        else
            log "INFO" "Installing gh extension: $ext_name..."
            gh extension install "$ext"
            log "SUCCESS" "gh extension '$ext_name' installed"
        fi
    done
}

# Main installation flow
main() {
    banner
    
    log "INFO" "Starting dotfiles installation..."
    log "INFO" "Logging to: $LOG_FILE"
    
    local os_type
    os_type=$(detect_os)
    
    case "$os_type" in
        macos)
            log "SUCCESS" "Detected macOS"
            install_homebrew
            install_macos_packages
            ;;
        arch)
            log "SUCCESS" "Detected Arch Linux"
            install_yay
            install_arch_packages
            ;;
        *)
            log "ERROR" "Unsupported operating system: $OSTYPE"
            log "ERROR" "This script supports macOS and Arch Linux only"
            exit 1
            ;;
    esac
    
    # Install oh-my-zsh and powerlevel10k (cross-platform)
    install_ohmyzsh
    install_powerlevel10k
    
    # Install mise development tools
    install_mise_tools
    
    # Install gh extensions
    install_gh_extensions
    
    echo ""
    log "SUCCESS" "Installation complete!"
    echo ""
    print_color "${GREEN}Next steps:${NC}"
    print_color "  1. Run ${BLUE}./bootstrap.zsh${NC} to deploy dotfiles"
    print_color "  2. Restart your terminal or run ${BLUE}source ~/.zshrc${NC}"
    print_color "  3. Configure powerlevel10k: ${BLUE}p10k configure${NC}"
    echo ""
    print_color "${YELLOW}Maintenance:${NC}"
    print_color "  • Update everything: ${BLUE}topgrade${NC}"
    print_color "  • Or use: ${BLUE}mise run update${NC}"
    echo ""
}

# Run main
main
