#!/usr/bin/env bash

# Shared UI Library for Dotfiles Scripts
# Provides interactive (gum) and non-interactive modes

# Detect if we're in interactive mode
is_interactive() {
    # Interactive if:
    # 1. We have a TTY
    # 2. Not in CI
    # 3. Not in non-interactive mode (--non-interactive flag)
    if [[ -t 1 ]] && [[ -z "${CI:-}" ]] && [[ "${INTERACTIVE}" != "false" ]]; then
        return 0
    else
        return 1
    fi
}

# Check if gum is available
has_gum() {
    command -v gum &>/dev/null
}

# Spinner - show progress for long operations
# Usage: ui_spin "title" command args...
ui_spin() {
    local title="$1"
    shift
    
    if is_interactive && has_gum; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo "⏳ $title"
        "$@"
    fi
}

# Style text with optional color/formatting
# Usage: ui_style "text" [--foreground=color] [--bold] [--italic]
ui_style() {
    if is_interactive && has_gum; then
        gum style "$@"
    else
        # Fallback: just echo the first argument (the text)
        echo "$1"
    fi
}

# Confirm - ask yes/no question
# Usage: ui_confirm "question" && do_thing
ui_confirm() {
    local question="$1"
    local default="${2:-yes}"  # yes or no
    
    if is_interactive && has_gum; then
        if [[ "$default" == "yes" ]]; then
            gum confirm "$question"
        else
            gum confirm --default=false "$question"
        fi
    else
        # Non-interactive: default to yes for safety
        echo "❓ $question (auto-confirmed: $default)"
        [[ "$default" == "yes" ]]
    fi
}

# Choose - select from a list
# Usage: choice=$(ui_choose "prompt" "option1" "option2" "option3")
ui_choose() {
    local prompt="$1"
    shift
    local options=("$@")
    
    if is_interactive && has_gum; then
        gum choose --header="$prompt" "${options[@]}"
    else
        # Non-interactive: return first option
        echo "${options[0]}"
    fi
}

# Format - display formatted content
# Usage: ui_format "markdown or code content"
ui_format() {
    local content="$1"
    local type="${2:-markdown}"  # markdown or code
    
    if is_interactive && has_gum; then
        echo "$content" | gum format -t "$type"
    else
        echo "$content"
    fi
}

# Header - display a section header
# Usage: ui_header "Section Title"
ui_header() {
    local title="$1"
    
    if is_interactive && has_gum; then
        gum style \
            --foreground 212 \
            --border-foreground 212 \
            --border double \
            --align center \
            --width 50 \
            --margin "1 2" \
            --padding "1 4" \
            "$title"
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  $title"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
}

# Success message
# Usage: ui_success "Operation completed"
ui_success() {
    local message="$1"
    
    if is_interactive && has_gum; then
        gum style --foreground 10 "✓ $message"
    else
        echo "✓ $message"
    fi
}

# Error message
# Usage: ui_error "Something failed"
ui_error() {
    local message="$1"
    
    if is_interactive && has_gum; then
        gum style --foreground 9 "✗ $message"
    else
        echo "✗ $message" >&2
    fi
}

# Warning message
# Usage: ui_warn "This might be problematic"
ui_warn() {
    local message="$1"
    
    if is_interactive && has_gum; then
        gum style --foreground 11 "⚠ $message"
    else
        echo "⚠ $message"
    fi
}

# Info message
# Usage: ui_info "Helpful information"
ui_info() {
    local message="$1"
    
    if is_interactive && has_gum; then
        gum style --foreground 12 "ℹ $message"
    else
        echo "ℹ $message"
    fi
}

# Package preview - show what will be installed with confirmation
# Usage: ui_package_preview "Package Manager" "package1" "package2" ...
ui_package_preview() {
    local pm_name="$1"
    shift
    local packages=("$@")
    
    if is_interactive && has_gum; then
        ui_header "$pm_name Packages"
        
        # Format package list as markdown
        local package_list=""
        for pkg in "${packages[@]}"; do
            package_list+="- \`$pkg\`\n"
        done
        
        echo -e "$package_list" | gum format -t markdown
        echo ""
        
        ui_confirm "Install these packages?" || return 1
    else
        echo ""
        echo "📦 $pm_name packages to install:"
        for pkg in "${packages[@]}"; do
            echo "  - $pkg"
        done
        echo ""
    fi
}
