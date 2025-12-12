#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$DOTFILES_ROOT/Ubuntu/inventory/$(hostname)-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT_DIR"

{
  echo "### OS"
  lsb_release -a 2>/dev/null || true
  echo
  echo "### /etc/os-release"
  cat /etc/os-release 2>/dev/null || true
  echo
  echo "### Kernel"
  uname -a
} > "$OUT_DIR/system.txt"

if command -v apt-mark >/dev/null 2>&1; then
  apt-mark showmanual | sort > "$OUT_DIR/apt-manual.txt"
fi

if command -v flatpak >/dev/null 2>&1; then
  flatpak list --app > "$OUT_DIR/flatpak-apps.txt" || true
fi

echo "Wrote inventory to: $OUT_DIR"


