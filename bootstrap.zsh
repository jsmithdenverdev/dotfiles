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
    
    # Use find to get all files and directories, excluding .git directory
    find "$source_dir" -mindepth 1 -not -path '*/\.git/*' -not -name '.git' | while read item; do
        # Get the relative path from the source directory
        local relative_path="${item#$source_dir/}"
        
        # Skip excluded items
        should_exclude "$item" && continue
        
        # Calculate target path
        local target_path="$target_dir/$relative_path"
        
        if [[ -d "$item" ]]; then
            # Create directory in target if it doesn't exist and isn't excluded
            if ! should_exclude "$(basename "$item")"; then
                mkdir -p "$target_path"
            fi
        else
            # Get the directory part of the target path
            local target_dir_path="$(dirname "$target_path")"
            
            # Create parent directory if it doesn't exist
            mkdir -p "$target_dir_path"
            
            # Only create symlink if it doesn't already exist
            if [[ ! -e "$target_path" ]]; then
                ln -s "$item" "$target_path"
                echo "Created symlink: $target_path -> $item"
            fi
        fi
    done
}

# Start creating symlinks from the dotfiles directory
create_symlinks "$DOTFILES_DIR" "$TARGET_DIR"