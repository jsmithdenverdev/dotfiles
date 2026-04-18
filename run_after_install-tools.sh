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

run_mise_install() {
  ensure_path_entry "$HOME/.local/bin"
  if ! command_exists mise; then
    log "mise not found even after installation"
    return
  fi

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
      *)
        case "$ID_LIKE" in
          *arch*) os="arch" ;;
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
