# AGENTS.md - Dotfiles Repository Guide

This document provides guidelines for AI coding agents working in this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository containing shell configurations (zsh), editor configs (vim/neovim), terminal multiplexer settings (tmux), and other development environment configurations. The repository uses a symlink-based deployment system via `bootstrap.zsh`.

## Project Structure

```
.
├── install.sh              # Main dependency installer (macOS + Arch)
├── bootstrap.zsh           # Symlink deployment script
├── Brewfile                # macOS packages (Homebrew)
├── packages-arch.txt       # Arch Linux packages (official repos)
├── packages-aur.txt        # Arch Linux AUR packages
├── .mise.toml              # Development tool versions (Node, Python, Go, etc.)
├── .dotfiles-config        # Bootstrap exclusion configuration
├── .zshrc                  # Zsh shell configuration
├── .tmux.conf              # Tmux configuration
├── .vimrc                  # Vim entry point (sources from .config/vim/)
├── .config/
│   ├── alacritty/          # Alacritty terminal config
│   ├── nvim/               # Neovim configuration
│   ├── vim/                # Vim plugins and settings
│   │   ├── plugins.vim     # Vim plugin definitions (vim-plug)
│   │   ├── base.vim        # Core editor settings
│   │   ├── custom.vim      # Plugin-specific configurations
│   │   └── mappings.vim    # Key mappings
│   └── starship.toml       # Starship prompt configuration
├── backgrounds/            # Desktop backgrounds
└── test/                   # Tests for bootstrap script
```

## Development Commands

### Installation
```bash
# Install all dependencies (system packages + dev tools)
./install.sh

# Preview installation without making changes
./install.sh --dry-run

# Verbose output
./install.sh --verbose
```

### Bootstrap & Deployment
```bash
# Deploy dotfiles (creates symlinks to $HOME)
./bootstrap.zsh

# Deploy with verbose output
./bootstrap.zsh --verbose

# Dry run (preview changes without applying)
./bootstrap.zsh --dry-run

# Force overwrite existing files
./bootstrap.zsh --force
```

### Maintenance
```bash
# Update everything (Homebrew/yay, mise, vim plugins, etc.)
topgrade

# Or use mise task
mise run update
```

### Shell Management
```bash
# Reload zsh configuration
source ~/.zshrc

# Reload tmux configuration
tmux source-file ~/.tmux.conf
# Or use the built-in binding: <prefix>+r (Ctrl-a r)
```

### Vim/Neovim
```bash
# Install/update vim plugins
vim +PlugInstall +qall

# Update all plugins
vim +PlugUpdate +qall

# Clean unused plugins
vim +PlugClean +qall
```

### Git Operations
```bash
# View recent changes
git log --oneline -10

# Check repository status
git status

# Commit changes with descriptive message
git add <files>
git commit -m "description: brief summary of changes"
```

## Code Style Guidelines

### Shell Scripts (Zsh/Bash)

**File Structure:**
- Use `#!/bin/zsh` or `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Define constants at the top (colors, paths, versions)
- Group related functions together

**Naming Conventions:**
- Variables: `UPPERCASE` for constants, `lowercase_with_underscores` for local vars
- Functions: `lowercase_with_underscores`
- Use descriptive names that indicate purpose

**Style:**
- Indent with 4 spaces (or 2 for consistency with existing code)
- Quote variables: `"$variable"` to prevent word splitting
- Use `[[ ]]` for conditionals instead of `[ ]`
- Comment complex logic and non-obvious operations
- Use function-level comments for documentation

**Error Handling:**
- Check exit codes of important commands
- Use `|| { log "ERROR" "message"; exit 1; }` for critical failures
- Provide meaningful error messages with context

### Vim Configuration (VimScript)

**File Organization:**
- Separate concerns into dedicated files (plugins, base, custom, mappings)
- Source external files with `source ~/.config/vim/file.vim`
- Group related settings with comment headers

**Style:**
- Use double quotes for strings
- Comment sections with visual separators:
  ```vim
  " ---------------------------
  " Section Name
  " ---------------------------
  ```
- One setting per line for clarity
- Align related settings for readability

**Plugin Management:**
- Use vim-plug for plugin management
- Declare plugins in `plugins.vim`
- Configure plugins in `custom.vim`
- Use specific branches/tags when needed: `Plug 'user/repo', { 'branch': 'release' }`

**Key Mappings:**
- Set leader key explicitly: `let mapleader=" "`
- Document complex mappings with comments
- Group mappings by category (navigation, editing, plugin-specific)
- Use `<Leader>` for custom commands
- Avoid overriding common Vim operations

### Configuration Files (TOML, Conf)

**Style:**
- Follow the tool's documented format conventions
- Use comments to explain non-obvious settings
- Group related settings together
- Keep configurations minimal and purposeful

## Important Patterns & Conventions

### Bootstrap Script Pattern
- The `bootstrap.zsh` script manages dotfile deployment
- Excluded items are defined in `.dotfiles-config` via `EXCLUDE_ITEMS` array
- Always use dry-run mode first when testing deployment changes
- Backups are created automatically with timestamps: `file.backup-YYYYMMDDHHMMSS`

### Vim Plugin Configuration Pattern
1. Install plugin via `Plug` directive in `plugins.vim`
2. Configure plugin settings in `custom.vim`
3. Add plugin-specific key mappings to `mappings.vim` if needed
4. Run `:PlugInstall` to install new plugins

### Logging Pattern (Shell Scripts)
```bash
log "LEVEL" "message"  # Levels: INFO, WARN, ERROR, SUCCESS
```
- Logs write to `~/.dotfiles_bootstrap.log`
- ERROR messages always display to stderr
- INFO messages display when `--verbose` flag is set

## Path Management

**Key Paths:**
- Home directory: `$HOME` or `~`
- Dotfiles source: `$DOTFILES_DIR` (script directory)
- Config directory: `~/.config/`
- Vim plugins: `~/.vim/` or `~/.local/share/nvim/`
- Temp/swap files: `/tmp/`

**PATH Additions (in .zshrc):**
- Homebrew: `/opt/homebrew/bin` (macOS only)
- Local binaries: `~/.local/bin`
- mise: Automatically manages PATH for Node, Python, Go, Deno, Bun

## Environment Variables

**Essential Variables:**
- `EDITOR=code` - Default text editor (VSCode)
- `VISUAL=code` - Visual editor
- `ZSH` - Oh-My-Zsh installation path

## Testing & Validation

**Before Committing:**
1. Test bootstrap script with `--dry-run` flag
2. Verify shell configuration loads without errors: `zsh -c 'source ~/.zshrc'`
3. Check vim configuration loads: `vim -c 'checkhealth' -c 'q'` (neovim)
4. Ensure no syntax errors in shell scripts: `zsh -n script.zsh`

**Common Issues:**
- Symlinks breaking after moving dotfiles directory
- Vim plugins not loading (run `:PlugInstall`)
- Shell startup errors (check `~/.dotfiles_bootstrap.log`)

## Git Commit Message Style

Based on repository history, use imperative mood and concise descriptions:
- `add config for starship prompt, customizing layout`
- `update settings`
- `minor update for mac`
- `Disable custom tmux config`

Keep messages brief (1 line preferred) and action-oriented.

## Dependency Management

### Overview
This repository uses a hybrid approach optimized for macOS and Arch Linux:
- **System packages**: Brewfile (macOS) + packages-arch.txt/packages-aur.txt (Arch)
- **Dev tools**: mise (.mise.toml) - cross-platform version manager
- **Updates**: topgrade - universal updater

### System Packages

**macOS:**
```bash
# Required packages
brew bundle --file=Brewfile

# Generate Brewfile from current system
brew bundle dump --file=Brewfile --force
```

**Arch Linux:**
```bash
# Official repository packages
yay -S --needed - < packages-arch.txt

# AUR packages
yay -S --needed - < packages-aur.txt
```

### Development Tools

Managed by mise (.mise.toml):
```bash
# Install all tools from .mise.toml
mise install

# Add a new tool
mise use node@20

# Check for updates
mise outdated

# Update all tools
mise upgrade

# List installed tools
mise list
```

### Adding Dependencies

1. **System tool**:
   - macOS: Add to Brewfile
   - Arch: Add to packages-arch.txt (official) or packages-aur.txt (AUR)
   
2. **Programming language/dev tool**: Add to .mise.toml
   ```toml
   [tools]
   rust = "latest"
   ```
   
3. **Test**: Run `./install.sh --dry-run`

4. **Commit**: Update relevant files

### CI Dependencies

CI uses system package managers for linting tools:
- shellcheck, bats: via package manager
- vim-vint: via pip
- taplo: via package manager or mise

## Notes for Agents

1. **Always use dry-run first:** When modifying bootstrap or install scripts, test with `--dry-run`
2. **Preserve user customizations:** Don't overwrite user-specific paths or settings
3. **Maintain separation of concerns:** Keep plugins, base settings, custom configs, and mappings in separate vim files
4. **Test changes locally:** Shell and vim configurations can break the user's environment if incorrect
5. **Check for existing patterns:** Follow established conventions in the codebase (e.g., vim comment headers, logging format)
6. **Use mise for dev tools:** Node, Python, Go, Deno, Bun should be managed via mise, not manual PATH additions
7. **Document complex logic:** Shell scripts and vim configurations can be cryptic; add comments
8. **Respect the exclude list:** Don't commit files listed in `.dotfiles-config` or default excludes
9. **Cross-platform support:** Test that changes work on both macOS and Arch Linux
