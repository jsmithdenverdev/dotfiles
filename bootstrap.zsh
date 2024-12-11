#!/bin/zsh

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME"

# Create an array of items to exclude from symlinking
exclude_items=(
    ".git"
    "bootstrap.zsh"
    "$(basename "$DOTFILES_DIR")"  # Exclude the dotfiles directory itself
)

# Function to check if an item should be excluded
should_exclude() {
    local item="$1"
    for exclude in "${exclude_items[@]}"; do
        if [[ "$item" == "$exclude" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to create symlinks recursively
create_symlinks() {
    local source_dir="$1"
    local target_dir="$2"
    local relative_path="${3:-}"

    cd "$source_dir"
    
    for item in .*(.N) *(.N); do
        # Skip if the item doesn't exist or is . or ..
        [[ -e "$item" ]] || continue
        [[ "$item" == "." || "$item" == ".." ]] && continue
        
        # Skip excluded items
        should_exclude "$item" && continue
        
        local source_path="$source_dir/$item"
        local target_path="$target_dir/$item"
        
        if [[ -d "$source_path" ]]; then
            # Create directory in target if it doesn't exist
            mkdir -p "$target_path"
            # Recursively process subdirectories
            create_symlinks "$source_path" "$target_path" "${relative_path:+$relative_path/}$item"
        else
            # Remove existing symlink or file
            if [[ -L "$target_path" || -e "$target_path" ]]; then
                rm "$target_path"
            fi
            # Create symlink
            ln -s "$source_path" "$target_path"
            echo "Created symlink: $target_path -> $source_path"
        fi
    done
}

# Start creating symlinks from the dotfiles directory
create_symlinks "$DOTFILES_DIR" "$TARGET_DIR"