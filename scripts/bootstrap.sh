#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

backup_and_link() {
  local src="$1"
  local dest="$2"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"

  local dest_dir
  dest_dir="$(dirname "$dest")"
  as_user "mkdir -p '$dest_dir'"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    say "Backing up $dest -> $dest.bak.$ts"
    as_user "mv '$dest' '$dest.bak.$ts'"
  elif [[ -L "$dest" ]]; then
    as_user "rm -f '$dest'"
  fi

  say "Linking $dest -> $src"
  as_user "ln -s '$src' '$dest'"
}

install_zsh() {
  say "==> Zsh"
  bash "$DOTFILES_ROOT/shell/install_zsh.sh"
}

install_vscode_settings() {
  say "==> VS Code settings (best-effort)"

  local src="$DOTFILES_ROOT/vscode/settings.json"
  [[ -f "$src" ]] || return 0

  # VS Code
  backup_and_link "$src" "$TARGET_HOME/.config/Code/User/settings.json"
  # VSCodium
  backup_and_link "$src" "$TARGET_HOME/.config/VSCodium/User/settings.json"
  # Cursor
  backup_and_link "$src" "$TARGET_HOME/.config/Cursor/User/settings.json"
}

install_vscode_keybindings() {
  say "==> VS Code keybindings (best-effort)"

  local src="$DOTFILES_ROOT/vscode/keybindings.json"
  [[ -f "$src" ]] || return 0

  # VS Code
  backup_and_link "$src" "$TARGET_HOME/.config/Code/User/keybindings.json"
  # VSCodium
  backup_and_link "$src" "$TARGET_HOME/.config/VSCodium/User/keybindings.json"
  # Cursor
  backup_and_link "$src" "$TARGET_HOME/.config/Cursor/User/keybindings.json"
}

install_bin_scripts() {
  say "==> Useful scripts in ~/.local/bin"
  as_user "mkdir -p '$TARGET_HOME/.local/bin'"

  if [[ -f "$DOTFILES_ROOT/scripts/git/gcfg" ]]; then
    backup_and_link "$DOTFILES_ROOT/scripts/git/gcfg" "$TARGET_HOME/.local/bin/gcfg"
  fi

  if [[ -f "$DOTFILES_ROOT/scripts/git/git-editor" ]]; then
    backup_and_link "$DOTFILES_ROOT/scripts/git/git-editor" "$TARGET_HOME/.local/bin/git-editor"
  fi

  if [[ -f "$DOTFILES_ROOT/scripts/git/new_client.sh" ]]; then
    backup_and_link "$DOTFILES_ROOT/scripts/git/new_client.sh" "$TARGET_HOME/.local/bin/new_client"
  fi

  if [[ -f "$DOTFILES_ROOT/scripts/git/new_project.sh" ]]; then
    backup_and_link "$DOTFILES_ROOT/scripts/git/new_project.sh" "$TARGET_HOME/.local/bin/new_project"
  fi

  if [[ -f "$DOTFILES_ROOT/scripts/backup/export_secrets.sh" ]]; then
    backup_and_link "$DOTFILES_ROOT/scripts/backup/export_secrets.sh" "$TARGET_HOME/.local/bin/export_secrets"
  fi

  if [[ -f "$DOTFILES_ROOT/scripts/backup/import_secrets.sh" ]]; then
    backup_and_link "$DOTFILES_ROOT/scripts/backup/import_secrets.sh" "$TARGET_HOME/.local/bin/import_secrets"
  fi
}

install_gitconfig() {
  say "==> Git config (best-effort)"

  local src="$DOTFILES_ROOT/git/.gitconfig"
  [[ -f "$src" ]] || return 0

  backup_and_link "$src" "$TARGET_HOME/.gitconfig"

  # Where per-client configs should live (not versioned)
  as_user "mkdir -p '$TARGET_HOME/.config/git/clients'"

  # Global gitignore
  if [[ -f "$DOTFILES_ROOT/git/ignore_global" ]]; then
    backup_and_link "$DOTFILES_ROOT/git/ignore_global" "$TARGET_HOME/.config/git/ignore_global"
  fi
}

install_ssh_config() {
  say "==> SSH config (best-effort)"

  local src="$DOTFILES_ROOT/ssh/config"
  [[ -f "$src" ]] || return 0

  backup_and_link "$src" "$TARGET_HOME/.ssh/config"
  as_user "mkdir -p '$TARGET_HOME/.ssh/config.d' '$TARGET_HOME/.ssh/keys'"
  as_user "chmod 700 '$TARGET_HOME/.ssh' '$TARGET_HOME/.ssh/config.d' '$TARGET_HOME/.ssh/keys' || true"
}

main() {
  install_zsh
  install_vscode_settings
  install_vscode_keybindings
  install_gitconfig
  install_ssh_config
  install_bin_scripts
  say "Bootstrap completed."
}

main "$@"


