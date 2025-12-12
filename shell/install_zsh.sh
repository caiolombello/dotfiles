#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { say "ERROR: $*"; exit 1; }

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSHRC_SRC="$DOTFILES_ROOT/shell/config/.zshrc"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"
TARGET_HOME="${TARGET_HOME:-$HOME}"

as_user() {
  if [[ "$TARGET_USER" != "$USER" ]]; then
    sudo -u "$TARGET_USER" -H bash -lc "$*"
  else
    bash -lc "$*"
  fi
}

detect_pm() {
  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  elif command -v dnf >/dev/null 2>&1; then
    echo "dnf"
  elif command -v pacman >/dev/null 2>&1; then
    echo "pacman"
  else
    echo ""
  fi
}

install_packages() {
  local pm="$1"; shift
  local pkgs=("$@")

  case "$pm" in
    apt)
      sudo apt-get update -y
      for pkg in "${pkgs[@]}"; do
        sudo apt-get install -y "$pkg" || say "Skipping missing package: $pkg"
      done
      ;;
    dnf)
      for pkg in "${pkgs[@]}"; do
        sudo dnf install -y "$pkg" || say "Skipping missing package: $pkg"
      done
      ;;
    pacman)
      sudo pacman -Sy --noconfirm
      for pkg in "${pkgs[@]}"; do
        sudo pacman -S --noconfirm "$pkg" || say "Skipping missing package: $pkg"
      done
      ;;
    *)
      die "Unsupported distribution (no apt/dnf/pacman)."
      ;;
  esac
}

clone_or_update() {
  local repo="$1"
  local dest="$2"

  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull --ff-only || true
  else
    rm -rf "$dest"
    git clone --depth=1 "$repo" "$dest"
  fi
}

install_oh_my_posh() {
  local arch
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) arch="amd64" ;;
  esac

  local omp_dir="$TARGET_HOME/.local/bin"
  local omp_bin="$omp_dir/oh-my-posh"
  local omp_url="https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$arch"
  local theme_dir="$TARGET_HOME/.poshthemes"
  local theme_url="https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_modern.omp.json"

  as_user "mkdir -p '$omp_dir' '$theme_dir'"

  if [[ ! -f "$omp_bin" ]]; then
    say "Downloading oh-my-posh ($arch) to $omp_bin"
    as_user "curl -fsSL '$omp_url' -o '$omp_bin'"
    as_user "chmod +x '$omp_bin'"
  fi

  if [[ ! -f "$theme_dir/powerlevel10k_modern.omp.json" ]]; then
    say "Downloading oh-my-posh theme to $theme_dir"
    as_user "curl -fsSL '$theme_url' -o '$theme_dir/powerlevel10k_modern.omp.json'"
  fi
}

install_oh_my_zsh_and_plugins() {
  local zsh_dir="$TARGET_HOME/.oh-my-zsh"
  local custom_dir="$zsh_dir/custom"
  local plugin_dir="$custom_dir/plugins"

  as_user "mkdir -p '$plugin_dir'"
  as_user "$(declare -f clone_or_update); clone_or_update https://github.com/ohmyzsh/ohmyzsh.git '$zsh_dir'"
  as_user "$(declare -f clone_or_update); clone_or_update https://github.com/zsh-users/zsh-autosuggestions '$plugin_dir/zsh-autosuggestions'"
  as_user "$(declare -f clone_or_update); clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git '$plugin_dir/zsh-syntax-highlighting'"
  as_user "$(declare -f clone_or_update); clone_or_update https://github.com/zsh-users/zsh-history-substring-search '$plugin_dir/zsh-history-substring-search'"
  as_user "$(declare -f clone_or_update); clone_or_update https://github.com/zsh-users/zsh-completions '$plugin_dir/zsh-completions'"
}

install_zshrc_symlink() {
  [[ -f "$ZSHRC_SRC" ]] || die "Missing $ZSHRC_SRC"

  local dest="$TARGET_HOME/.zshrc"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    say "Backing up existing $dest -> $dest.bak.$ts"
    as_user "mv '$dest' '$dest.bak.$ts'"
  elif [[ -L "$dest" ]]; then
    as_user "rm -f '$dest'"
  fi

  say "Linking $dest -> $ZSHRC_SRC"
  as_user "ln -s '$ZSHRC_SRC' '$dest'"
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  [[ -n "$zsh_path" ]] || die "zsh not found after install"

  # This will prompt for password if needed, but doesn't require interactive TTY.
  sudo chsh -s "$zsh_path" "$TARGET_USER" || true
}

main() {
  local pm
  pm="$(detect_pm)"
  [[ -n "$pm" ]] || die "No supported package manager found."

  say "Installing base packages..."
  install_packages "$pm" zsh git curl wget ca-certificates

  # Useful tools (best-effort across distros)
  say "Installing optional dev tools (best-effort)..."
  case "$pm" in
    apt)
      install_packages "$pm" ripgrep fd-find bat fzf eza delta
      ;;
    dnf)
      install_packages "$pm" ripgrep fd-find bat fzf eza git-delta
      ;;
    pacman)
      install_packages "$pm" ripgrep fd bat fzf eza git-delta
      ;;
  esac

  say "Installing Oh My Zsh + plugins..."
  install_oh_my_zsh_and_plugins

  say "Installing Oh My Posh..."
  install_oh_my_posh

  say "Installing .zshrc symlink..."
  install_zshrc_symlink

  say "Setting zsh as default shell..."
  set_default_shell

  say "Done. Log out/in (or start a new terminal) to use zsh."
}

main "$@"
