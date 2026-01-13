#!/usr/bin/env bash

# Unified Dotfiles Management Script
# Provides a single entry point for install and bootstrap operations

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print banner
banner() {
    echo ""
    echo "▄ ▄▖▄▖▄▖▄▖▖ ▄▖▄▖"
    echo "▌▌▌▌▐ ▙▖▐ ▌ ▙▖▚ "
    echo "▙▘▙▌▐ ▌ ▟▖▙▖▙▖▄▌"
    echo ""
}

# Print colored message
print_msg() {
    local color="$1"
    shift
    echo -e "${color}$*${NC}"
}

# Show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

Unified dotfiles management script - install dependencies and deploy configurations.

COMMANDS:
    install     Install system dependencies (packages, tools, frameworks)
    bootstrap   Deploy dotfiles (create symlinks)
    all         Run both install and bootstrap
    menu        Show interactive menu (default if no command)

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Show detailed output
    -n, --dry-run           Preview without making changes
    --non-interactive       Disable interactive prompts

EXAMPLES:
    ./dotfiles.sh                    # Show interactive menu
    ./dotfiles.sh all                # Run install + bootstrap
    ./dotfiles.sh install            # Install dependencies only
    ./dotfiles.sh bootstrap          # Deploy dotfiles only
    ./dotfiles.sh all --dry-run      # Preview all operations

EOF
}

# Check if gum is available
has_gum() {
    command -v gum &>/dev/null
}

# Interactive menu
show_menu() {
    if has_gum && [[ -t 1 ]]; then
        # Interactive mode with gum
        gum style \
            --foreground 212 \
            --border double \
            --padding "1 2" \
            "Dotfiles Management"
        
        echo ""
        local choice
        choice=$(gum choose \
            "Install dependencies (packages, tools)" \
            "Bootstrap dotfiles (symlinks)" \
            "Run both (full setup)" \
            "Exit")
        
        case "$choice" in
            "Install dependencies"*)
                run_install
                ;;
            "Bootstrap dotfiles"*)
                run_bootstrap
                ;;
            "Run both"*)
                run_all
                ;;
            "Exit")
                echo "Goodbye!"
                exit 0
                ;;
        esac
    else
        # Non-interactive mode
        print_msg "$BLUE" "=== Dotfiles Management Menu ==="
        echo ""
        echo "1) Install dependencies (packages, tools)"
        echo "2) Bootstrap dotfiles (symlinks)"
        echo "3) Run both (full setup)"
        echo "4) Exit"
        echo ""
        read -rp "Choose an option [1-4]: " choice
        
        case "$choice" in
            1)
                run_install
                ;;
            2)
                run_bootstrap
                ;;
            3)
                run_all
                ;;
            4)
                echo "Goodbye!"
                exit 0
                ;;
            *)
                print_msg "$RED" "Invalid choice"
                exit 1
                ;;
        esac
    fi
}

# Run install script
run_install() {
    print_msg "$GREEN" "→ Running install script..."
    echo ""
    
    if [[ -f "$SCRIPT_DIR/install.sh" ]]; then
        "$SCRIPT_DIR/install.sh" "$@"
    else
        print_msg "$RED" "Error: install.sh not found"
        exit 1
    fi
}

# Run bootstrap script
run_bootstrap() {
    print_msg "$GREEN" "→ Running bootstrap script..."
    echo ""
    
    if [[ -f "$SCRIPT_DIR/bootstrap.zsh" ]]; then
        "$SCRIPT_DIR/bootstrap.zsh" "$@"
    else
        print_msg "$RED" "Error: bootstrap.zsh not found"
        exit 1
    fi
}

# Run both scripts
run_all() {
    print_msg "$BLUE" "=== Running Full Setup ==="
    echo ""
    
    print_msg "$YELLOW" "Step 1/2: Installing dependencies..."
    run_install "$@"
    
    echo ""
    print_msg "$YELLOW" "Step 2/2: Bootstrapping dotfiles..."
    run_bootstrap "$@"
    
    echo ""
    print_msg "$GREEN" "✓ Full setup complete!"
}

# Main function
main() {
    # Parse command
    local command="${1:-menu}"
    
    # Handle help flag
    if [[ "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # Shift if we have a command
    if [[ "$command" != "menu" ]] && [[ "$command" != "-"* ]]; then
        shift
    fi
    
    # Execute command
    case "$command" in
        menu)
            banner
            show_menu "$@"
            ;;
        install)
            banner
            run_install "$@"
            ;;
        bootstrap)
            banner
            run_bootstrap "$@"
            ;;
        all)
            banner
            run_all "$@"
            ;;
        *)
            print_msg "$RED" "Unknown command: $command"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main
main "$@"
