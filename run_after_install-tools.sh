#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[chezmoi] %s\n' "$*"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

run_as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
    return
  fi

  if command_exists sudo; then
    sudo "$@"
  else
    log "sudo is required to run '$*'"
    exit 1
  fi
}

ensure_path_entry() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

source_dir="${CHEZMOI_SOURCE_DIR:-$(chezmoi source-path)}"

install_macos_packages() {
  if ! command_exists brew; then
    log "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -e /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi

  log "Running brew bundle"
  brew bundle --file="$source_dir/Brewfile"
}

ensure_yay() {
  if command_exists yay; then
    return
  fi

  log "Installing yay"
  run_as_root pacman -S --needed --noconfirm base-devel git
  tmp_dir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
  (cd "$tmp_dir/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp_dir"
}

install_arch_packages() {
  ensure_yay
  yay_flags=(
    --noconfirm
    --sudoloop
    --noprogressbar
    --answerdiff
    None
    --answerclean
    All
    --removemake
    --cleanafter
    --noredownload
    --norebuild
  )
  log "Installing Arch packages"
  if command_exists script; then
    script -qec "yay ${yay_flags[*]} -S --needed - < '$source_dir/packages-arch.txt'" /dev/null
  else
    yay "${yay_flags[@]}" -S --needed - < "$source_dir/packages-arch.txt"
  fi
}

ensure_mise() {
  if command_exists mise; then
    return
  fi

  log "Installing mise"
  curl https://mise.run | sh
  ensure_path_entry "$HOME/.local/bin"
}

ensure_github_cli_repo() {
  if command_exists gh; then
    return
  fi

  local list_file="/etc/apt/sources.list.d/github-cli.list"
  local keyring="/usr/share/keyrings/githubcli-archive-keyring.gpg"
  if [[ -f $list_file ]]; then
    return
  fi

  log "Adding GitHub CLI apt repository"
  local tmp_key
  tmp_key=$(mktemp)
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o "$tmp_key"
  run_as_root install -o root -g root -m 644 "$tmp_key" "$keyring"
  rm -f "$tmp_key"
  local arch
  arch=$(dpkg --print-architecture)
  printf 'deb [arch=%s signed-by=%s] https://cli.github.com/packages stable main\n' "$arch" "$keyring" |
    run_as_root tee "$list_file" >/dev/null
}

ensure_fd_shortcut() {
  if command_exists fd || ! command_exists fdfind; then
    return
  fi

  log "Creating fd shortcut for fdfind"
  run_as_root install -d /usr/local/bin
  run_as_root ln -sf "$(command -v fdfind)" /usr/local/bin/fd
}

ensure_bat_shortcut() {
  if command_exists bat || ! command_exists batcat; then
    return
  fi

  log "Creating bat shortcut for batcat"
  run_as_root install -d /usr/local/bin
  run_as_root ln -sf "$(command -v batcat)" /usr/local/bin/bat
}

install_ubuntu_packages() {
  log "Installing Ubuntu packages"

  run_as_root apt-get update

  local prerequisites=(
    apt-transport-https
    ca-certificates
    curl
    gnupg
  )
  run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${prerequisites[@]}"

  ensure_github_cli_repo

  run_as_root apt-get update

  local packages=()
  if [[ -f "$source_dir/packages-ubuntu.txt" ]]; then
    while IFS= read -r line; do
      [[ -z $line || $line =~ ^# ]] && continue
      packages+=("$line")
    done <"$source_dir/packages-ubuntu.txt"
  fi

  if (( ${#packages[@]} )); then
    run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
  fi

  ensure_fd_shortcut
  ensure_bat_shortcut
}

trust_mise_config() {
  local mise_config="$HOME/.mise.toml"
  if [[ ! -f "$mise_config" ]]; then
    return
  fi

  if ! command_exists mise; then
    return
  fi

  log "Trusting mise configuration $mise_config"
  if ! mise trust --yes "$mise_config" >/dev/null 2>&1; then
    log "Failed to trust $mise_config"
  fi
}

run_mise_install() {
  ensure_path_entry "$HOME/.local/bin"
  if [[ -f "$HOME/.mise.toml" ]]; then
    export MISE_TRUSTED_CONFIG_PATHS="${MISE_TRUSTED_CONFIG_PATHS:+$MISE_TRUSTED_CONFIG_PATHS:}$HOME/.mise.toml"
  fi
  export MISE_PYTHON_GITHUB_ATTESTATIONS=${MISE_PYTHON_GITHUB_ATTESTATIONS:-false}
  if ! command_exists mise; then
    log "mise not found even after installation"
    return
  fi

  trust_mise_config
  log "Running mise install"
  mise install
}

run_gh_extensions() {
  if ! command_exists gh; then
    return
  fi
  gh_extensions=("dlvhdr/gh-dash")
  for ext in "${gh_extensions[@]}"; do
    log "Ensuring gh extension $ext"
    gh extension install "$ext" >/dev/null 2>&1 || true
  done
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    return
  fi

  log "Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_powerlevel10k() {
  local theme_dir="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  if [[ -d "$theme_dir" ]]; then
    return
  fi

  log "Installing Powerlevel10k theme"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
}

install_tpm() {
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -d "$tpm_dir" ]]; then
    return
  fi

  log "Installing tmux plugin manager (TPM)"
  git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
}

main() {
  if [[ ${CHEZMOI_INSTALL_TOOLS:-1} -ne 1 ]]; then
    log "Skipping tool installation (CHEZMOI_INSTALL_TOOLS=$CHEZMOI_INSTALL_TOOLS)"
    return
  fi

  os="unknown"
  if [[ $(uname) == "Darwin" ]]; then
    os="macos"
  elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
      arch|endeavouros|manjaro) os="arch" ;;
      ubuntu|debian|pop|linuxmint) os="ubuntu" ;;
      *)
        case "$ID_LIKE" in
          *arch*) os="arch" ;;
          *debian*) os="ubuntu" ;;
        esac
        ;;
    esac
  fi

  case "$os" in
    macos)
      install_macos_packages
      ;;
    arch)
      install_arch_packages
      ;;
    ubuntu)
      install_ubuntu_packages
      ;;
    *)
      log "Unsupported OS ($os), skipping package installation"
      ;;
  esac

  ensure_mise
  run_mise_install
  run_gh_extensions
  install_oh_my_zsh
  install_powerlevel10k
  install_tpm
}

main
