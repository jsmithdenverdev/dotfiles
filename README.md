# Dotfiles

Personal development environment configuration for macOS and Arch Linux.

## Features

- **Cross-platform**: Works on macOS (Homebrew) and Arch Linux (pacman/yay)
- **Version management**: mise for Node.js, Python, Go, Deno, and Bun
- **Modern CLI tools**: ripgrep, fd, fzf, bat, eza, and more
- **Zsh configuration**: oh-my-zsh with powerlevel10k theme
- **Vim/Neovim**: Pre-configured with useful plugins
- **One-command updates**: topgrade keeps everything up to date

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### 2. Install dependencies

```bash
./install.sh
```

This will:
- Install system packages (git, zsh, neovim, etc.)
- Install oh-my-zsh and powerlevel10k theme
- Install mise and development tools (Node, Python, Go, etc.)

### 3. Deploy dotfiles

```bash
./bootstrap.zsh
```

This creates symlinks from this repository to your home directory.

### 4. Restart your terminal

```bash
# Or reload your shell
source ~/.zshrc
```

### 5. Configure powerlevel10k (optional)

```bash
p10k configure
```

## Installation Options

### Dry run (preview without installing)

```bash
./install.sh --dry-run
```

### Verbose output

```bash
./install.sh --verbose
```

### Skip optional packages

```bash
./install.sh --skip-optional
```

## Daily Usage

### Update everything

```bash
topgrade
```

Or use the mise task:

```bash
mise run update
```

### Run tests

```bash
mise run test
# or: bats test/
```

### Run linters

```bash
mise run lint
# or: ./scripts/lint.sh
```

### Deploy dotfiles

```bash
mise run deploy
# or: ./bootstrap.zsh
```

## Managing Dependencies

### System Packages

**macOS:**
```bash
# Edit Brewfile, then run:
brew bundle --file=Brewfile
```

**Arch Linux:**
```bash
# Edit packages-arch.txt or packages-aur.txt, then run:
yay -S --needed - < packages-arch.txt
yay -S --needed - < packages-aur.txt
```

### Development Tools

Managed by mise in `.mise.toml`:

```bash
# Install all tools
mise install

# Add a new tool
mise use node@20

# Check for updates
mise outdated

# Update all tools
mise upgrade
```

## Adding New Tools

### System Package

1. **macOS**: Add to `Brewfile`
   ```ruby
   brew "package-name"
   ```

2. **Arch**: Add to `packages-arch.txt` (official) or `packages-aur.txt` (AUR)
   ```
   package-name
   ```

3. Run installer:
   ```bash
   ./install.sh
   ```

### Programming Language/Tool

1. Add to `.mise.toml`:
   ```toml
   [tools]
   rust = "latest"
   ```

2. Install:
   ```bash
   mise install
   ```

## Project Structure

```
.
├── install.sh              # Main installation script
├── bootstrap.zsh           # Dotfile deployment (creates symlinks)
├── Brewfile                # macOS packages (Homebrew)
├── packages-arch.txt       # Arch Linux packages (official repos)
├── packages-aur.txt        # Arch Linux AUR packages
├── .mise.toml              # Development tool versions
├── .zshrc                  # Zsh configuration
├── .tmux.conf              # Tmux configuration
├── .vimrc                  # Vim entry point
├── .config/
│   ├── alacritty/          # Alacritty terminal config
│   ├── nvim/               # Neovim configuration
│   ├── vim/                # Vim plugins and settings
│   └── starship.toml       # Starship prompt (alternative)
└── test/                   # Tests for bootstrap script
```

## Installed Tools

### System Tools

- **Shell**: zsh with oh-my-zsh and powerlevel10k
- **Editor**: neovim, vim, VSCode
- **Terminal**: Alacritty
- **Multiplexer**: tmux
- **Version Control**: git

### Modern CLI Utilities

- **ripgrep**: Fast grep replacement
- **fd**: Fast find replacement
- **fzf**: Fuzzy finder
- **bat**: Cat with syntax highlighting
- **eza**: Modern ls replacement
- **jq**: JSON processor
- **htop**: Process viewer

### Development Tools (via mise)

- **Node.js**: LTS version
- **Python**: 3.12.x
- **Go**: 1.21.x
- **Deno**: Latest
- **Bun**: Latest

### Databases

- **PostgreSQL**: Version 15

### Containerization

- **Docker**: Docker Desktop (macOS) or Docker Engine (Arch)

## Troubleshooting

### mise not found after installation

Restart your terminal or source your shell config:

```bash
source ~/.zshrc
```

### Homebrew command not found (macOS)

Homebrew should be added to PATH automatically. If not, run:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### yay not found (Arch)

The install script should install yay automatically. If it fails, install manually:

```bash
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay && makepkg -si
```

### Symlink conflicts

If `bootstrap.zsh` reports conflicts, backup your existing dotfiles:

```bash
./bootstrap.zsh --dry-run  # Preview changes
./bootstrap.zsh --force    # Overwrite existing files
```

### mise install fails

Check which tool failed and install manually:

```bash
mise install node@lts
mise install python@3.12
# etc.
```

## Customization

### Change default editor

Edit `.mise.toml` or `.zshrc`:

```bash
export EDITOR="nvim"
export VISUAL="nvim"
```

### Add custom aliases

Add to `.zshrc`:

```bash
# Custom aliases
alias ll='eza -la'
alias cat='bat'
```

### Modify vim/neovim plugins

Edit `.config/vim/plugins.vim` and run:

```bash
vim +PlugInstall +qall
```

## Maintenance

### Update everything at once

```bash
topgrade
```

This updates:
- Homebrew packages (macOS) or pacman/yay (Arch)
- mise tools
- npm global packages
- Vim/Neovim plugins
- oh-my-zsh
- And more!

### Update specific package managers

```bash
# macOS
brew update && brew upgrade

# Arch
yay -Syu

# mise tools
mise upgrade
```

## Contributing

Feel free to fork this repository and customize it for your own needs!

## License

MIT License - Feel free to use and modify as needed.
