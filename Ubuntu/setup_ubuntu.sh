#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { say "ERROR: $*"; exit 1; }

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }

install_apt_packages_from_file() {
  local file="$1"
  [[ -f "$file" ]] || die "Missing package list: $file"

  sudo apt-get update -y
  # Best-effort: if a package doesn't exist on a given Ubuntu/Pop release, skip it.
  while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    [[ "$pkg" =~ ^# ]] && continue
    sudo apt-get install -y "$pkg" || say "Skipping missing APT package: $pkg"
  done < "$file"
}

setup_flatpak() {
  if ! command -v flatpak >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y flatpak gnome-software-plugin-flatpak || true
  fi

  # Add Flathub (idempotent)
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
}

install_flatpak_apps() {
  local file="$DOTFILES_ROOT/Ubuntu/packages/flatpak-apps.txt"
  [[ -f "$file" ]] || return 0

  need_cmd flatpak
  while IFS= read -r app; do
    [[ -z "$app" ]] && continue
    [[ "$app" =~ ^# ]] && continue
    flatpak install -y --noninteractive flathub "$app" || say "Skipping flatpak app: $app"
  done < "$file"
}

setup_cursor() {
  # Cursor official APT repo (idempotent) + install
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg || true

  sudo install -m 0755 -d /etc/apt/keyrings
  if [[ ! -f /etc/apt/keyrings/cursor.gpg ]]; then
    curl -fsSL https://downloads.cursor.com/keys/anysphere.asc | sudo gpg --dearmor -o /etc/apt/keyrings/cursor.gpg
    sudo chmod a+r /etc/apt/keyrings/cursor.gpg
  fi

  # Add repo (overwrite to keep it clean)
  echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/cursor.gpg] https://downloads.cursor.com/aptrepo stable main" | \
    sudo tee /etc/apt/sources.list.d/cursor.list >/dev/null

  sudo apt-get update -y
  sudo apt-get install -y cursor
}

setup_docker() {
  # Prefer Docker official repo (so docker-ce exists), then fallback to docker.io.
  if ! command -v docker >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg || true

    # Official Docker repo (idempotent)
    sudo install -m 0755 -d /etc/apt/keyrings
    if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
      sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    . /etc/os-release
    local arch
    arch="$(dpkg --print-architecture)"
    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || \
      sudo apt-get install -y docker.io docker-compose-plugin || true
  fi

  if command -v docker >/dev/null 2>&1; then
    sudo systemctl enable --now docker 2>/dev/null || true
    sudo usermod -aG docker "$USER" || true
    say "Docker ok. You may need to log out/in for docker group to apply."
  fi
}

run_bootstrap() {
  bash "$DOTFILES_ROOT/scripts/bootstrap.sh"
}

run_gpg_setup() {
  bash "$DOTFILES_ROOT/scripts/gpg/setup_gpg.sh"
}

usage() {
  cat <<EOF
Usage: ./Ubuntu/setup_ubuntu.sh [flags]

Flags:
  --base          Install base APT packages (Ubuntu/packages/apt-base.txt)
  --desktop       Install desktop APT packages (Ubuntu/packages/apt-desktop.txt)
  --cursor        Install Cursor editor (official APT repo)
  --docker        Install Docker (best-effort) + add user to docker group
  --flatpak       Install flatpak + add Flathub
  --flatpak-apps  Install flatpak apps from Ubuntu/packages/flatpak-apps.txt
  --gpg           Run scripts/gpg/setup_gpg.sh
  --bootstrap     Run scripts/bootstrap.sh (Zsh + VSCode settings + scripts)
  --all           Run: base + desktop + cursor + docker + flatpak + flatpak-apps + bootstrap
EOF
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

need_cmd sudo
need_cmd apt-get

  local do_base=0 do_desktop=0 do_cursor=0 do_docker=0 do_flatpak=0 do_flatpak_apps=0 do_gpg=0 do_bootstrap=0

for arg in "$@"; do
  case "$arg" in
    --base) do_base=1 ;;
    --desktop) do_desktop=1 ;;
    --cursor) do_cursor=1 ;;
    --docker) do_docker=1 ;;
    --flatpak) do_flatpak=1 ;;
    --flatpak-apps) do_flatpak_apps=1 ;;
    --gpg) do_gpg=1 ;;
    --bootstrap) do_bootstrap=1 ;;
    --all)
      do_base=1
      do_desktop=1
      do_cursor=1
      do_docker=1
      do_flatpak=1
      do_flatpak_apps=1
      do_bootstrap=1
      ;;
    *)
      die "Unknown flag: $arg (use --help)"
      ;;
  esac
done

if (( do_base )); then
  say "==> Base APT packages"
  install_apt_packages_from_file "$DOTFILES_ROOT/Ubuntu/packages/apt-base.txt"
fi

if (( do_desktop )); then
  say "==> Desktop APT packages"
  install_apt_packages_from_file "$DOTFILES_ROOT/Ubuntu/packages/apt-desktop.txt"
fi

if (( do_cursor )); then
  say "==> Cursor"
  setup_cursor
fi

if (( do_docker )); then
  say "==> Docker"
  setup_docker
fi

if (( do_flatpak )); then
  say "==> Flatpak + Flathub"
  setup_flatpak
fi

if (( do_flatpak_apps )); then
  say "==> Flatpak apps"
  install_flatpak_apps
fi

if (( do_gpg )); then
  say "==> GPG setup"
  run_gpg_setup
fi

if (( do_bootstrap )); then
  say "==> Dotfiles bootstrap"
  run_bootstrap
fi

say "Setup completed."
}

main "$@"


