# AGENTS.md - Dotfiles Repository Guide

This document provides guidelines for AI coding agents working in this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository containing shell configurations (zsh), editor configs (vim/neovim), terminal multiplexer settings (tmux), and other development environment configurations. The repository uses a symlink-based deployment system via `bootstrap.zsh`.

## Project Structure

```
.
├── bootstrap.zsh           # Symlink deployment script
├── .dotfiles-config        # Bootstrap exclusion configuration
├── .zshrc                  # Zsh shell configuration
├── .tmux.conf             # Tmux configuration
├── .vimrc                 # Vim entry point (sources from .config/vim/)
├── .config/
│   ├── alacritty/         # Alacritty terminal config
│   ├── nvim/              # Neovim configuration
│   ├── vim/               # Vim plugins and settings
│   │   ├── plugins.vim    # Vim plugin definitions (vim-plug)
│   │   ├── base.vim       # Core editor settings
│   │   ├── custom.vim     # Plugin-specific configurations
│   │   └── mappings.vim   # Key mappings
│   ├── starship.toml      # Starship prompt configuration
│   └── Windsurf/          # Windsurf IDE settings
└── backgrounds/           # Desktop backgrounds
```

## Development Commands

### Bootstrap & Installation
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

### CI/CD & Testing

**Run all linters locally:**
```bash
# Run all linters with helper script
./scripts/lint.sh

# Or run individually:
shellcheck bootstrap.zsh .zshrc
vint .vimrc .config/vim/*.vim .config/nvim/init.vim
taplo fmt --check .config/**/*.toml
```

**Run tests locally:**
```bash
# Run all tests
bats test/

# Run with verbose output
bats -t test/

# Run specific test file
bats test/bootstrap.bats
```

**CI Pipeline:**
- All PRs must pass CI checks before merging to `master`
- Required status checks: `lint-shell`, `lint-vim`, `lint-toml`, `test`
- Tests run on Ubuntu latest
- Workflow defined in `.github/workflows/ci.yml`

**Writing Tests:**
- Test files go in `test/` directory
- Use Bats framework (Bash Automated Testing System)
- Follow existing test patterns in `test/bootstrap.bats`
- Helper functions available in `test/test_helper.bash`
- Tests should be idempotent and isolated

**Local Development Requirements:**
```bash
# Install ShellCheck (macOS)
brew install shellcheck

# Install Vint
pip install vim-vint

# Install taplo
cargo install taplo-cli --locked
# OR: npm install -g @taplo/cli

# Install Bats
brew install bats-core
# OR: npm install -g bats
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
- Homebrew: `/opt/homebrew/bin`
- Local binaries: `~/.local/bin`
- Go binaries: `$(go env GOPATH)/bin`
- Bun: `~/.bun/bin`
- Deno: via `.deno/env`
- Node: via NVM

## Environment Variables

**Essential Variables:**
- `EDITOR=nvim` - Default text editor
- `DOCKER_HOST` - Colima Docker socket location
- `NVM_DIR` - Node Version Manager directory
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

## Notes for Agents

1. **Always use dry-run first:** When modifying bootstrap script or deployment logic, test with `--dry-run`
2. **Preserve user customizations:** Don't overwrite user-specific paths or settings
3. **Maintain separation of concerns:** Keep plugins, base settings, custom configs, and mappings in separate vim files
4. **Test changes locally:** Shell and vim configurations can break the user's environment if incorrect
5. **Check for existing patterns:** Follow established conventions in the codebase (e.g., vim comment headers, logging format)
6. **Be conservative with PATH:** Only add to PATH if absolutely necessary
7. **Document complex logic:** Shell scripts and vim configurations can be cryptic; add comments
8. **Respect the exclude list:** Don't commit files listed in `.dotfiles-config` or default excludes
