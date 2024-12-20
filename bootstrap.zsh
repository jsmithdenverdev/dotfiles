#!/bin/zsh

# Exit on error, undefined variable, or pipe failure
set -euo pipefail

# Script version
VERSION="1.0.0"

# Initialize logging
LOG_FILE="${HOME}/.dotfiles_bootstrap.log"
VERBOSE=false
DRY_RUN=false
FORCE=false

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory using zsh-specific method
DOTFILES_DIR="${0:A:h}"
TARGET_DIR="$HOME"
CONFIG_FILE="${DOTFILES_DIR}/.dotfiles-config"

# Default exclude items if config doesn't exist
DEFAULT_EXCLUDE_ITEMS=(
    ".git"
    "bootstrap.zsh"
    "$(basename "$DOTFILES_DIR")"
    ".dotfiles-config"
    ".DS_Store"
)

# Logging functions
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    
    if [[ "$VERBOSE" == "true" ]] || [[ "$level" == "ERROR" ]]; then
        case "$level" in
            "ERROR") echo -e "${RED}[ERROR]${NC} ${message}" >&2 ;;
            "WARN")  echo -e "${YELLOW}[WARN]${NC} ${message}" ;;
            "INFO")  echo -e "${BLUE}[INFO]${NC} ${message}" ;;
            "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} ${message}" ;;
        esac
    fi
}

# Usage information
usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -f, --force     Force overwrite existing files
    -d, --dry-run   Show what would be done without making changes
    --version       Show version information

Description:
    Bootstrap script for managing dotfiles symlinks.
    Creates symlinks from $DOTFILES_DIR to $TARGET_DIR
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -v|--verbose) VERBOSE=true ;;
        -f|--force) FORCE=true ;;
        -d|--dry-run) DRY_RUN=true ;;
        --version) echo "bootstrap.zsh version $VERSION"; exit 0 ;;
        *) log "ERROR" "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

# Load configuration file if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    exclude_items=("${EXCLUDE_ITEMS[@]}")
else
    exclude_items=("${DEFAULT_EXCLUDE_ITEMS[@]}")
fi

# Backup function
backup_file() {
    local file="$1"
    local backup="${file}.backup-$(date +%Y%m%d%H%M%S)"
    
    if [[ -e "$file" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "Would backup $file to $backup"
            return 0
        fi
        
        if cp -R "$file" "$backup"; then
            log "INFO" "Created backup: $backup"
            return 0
        else
            log "ERROR" "Failed to create backup of $file"
            return 1
        fi
    fi
}

# Function to check if an item should be excluded
should_exclude() {
    local item="$1"
    
    # Check if the path contains .git
    if [[ "$item" == *".git"* ]]; then
        return 0
    fi
    
    # Check against exclude list
    for exclude in "${exclude_items[@]}"; do
        if [[ "$(basename "$item")" == "$exclude" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to create symlinks recursively
create_symlinks() {
    local source_dir="$1"
    local target_dir="$2"
    
    # Check if source directory exists
    if [[ ! -d "$source_dir" ]]; then
        log "ERROR" "Source directory does not exist: $source_dir"
        exit 1
    fi
    
    # Check if target directory exists or create it
    if [[ ! -d "$target_dir" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "Would create directory: $target_dir"
        else
            mkdir -p "$target_dir" || {
                log "ERROR" "Failed to create target directory: $target_dir"
                exit 1
            }
        fi
    fi
    
    # Use zsh native globbing for better performance
    for item in "$source_dir"/**/*(.D); do
        # Get the relative path from the source directory
        local relative_path="${item#$source_dir/}"
        
        # Skip excluded items
        should_exclude "$item" && continue
        
        # Calculate target path
        local target_path="$target_dir/$relative_path"
        
        # Handle existing files
        if [[ -e "$target_path" ]]; then
            if [[ "$FORCE" == "true" ]]; then
                if [[ "$DRY_RUN" == "false" ]]; then
                    backup_file "$target_path"
                    rm -rf "$target_path"
                else
                    log "INFO" "Would remove: $target_path"
                fi
            elif [[ ! -L "$target_path" ]]; then
                log "WARN" "File exists and is not a symlink: $target_path (use --force to override)"
                continue
            elif [[ "$(readlink "$target_path")" == "$item" ]]; then
                log "INFO" "Symlink already exists and points to correct location: $target_path"
                continue
            fi
        fi
        
        # Create parent directory if needed
        local target_dir_path="$(dirname "$target_path")"
        if [[ ! -d "$target_dir_path" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log "INFO" "Would create directory: $target_dir_path"
            else
                mkdir -p "$target_dir_path" || {
                    log "ERROR" "Failed to create directory: $target_dir_path"
                    continue
                }
            fi
        fi
        
        # Create symlink
        if [[ "$DRY_RUN" == "true" ]]; then
            log "INFO" "Would create symlink: $target_path -> $item"
        else
            if ln -s "$item" "$target_path"; then
                log "SUCCESS" "Created symlink: $target_path -> $item"
            else
                log "ERROR" "Failed to create symlink: $target_path -> $item"
            fi
        fi
    done
}

# Main execution
log "INFO" "Starting dotfiles bootstrap (Version: $VERSION)"
log "INFO" "Source directory: $DOTFILES_DIR"
log "INFO" "Target directory: $TARGET_DIR"

if [[ "$DRY_RUN" == "true" ]]; then
    log "INFO" "Running in dry-run mode - no changes will be made"
fi

create_symlinks "$DOTFILES_DIR" "$TARGET_DIR"

log "SUCCESS" "Bootstrap completed successfully"