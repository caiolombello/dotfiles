#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { say "ERROR: $*"; exit 1; }

OUT_BASE="${1:-$HOME/dotfiles-backup}"
TS="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="${OUT_BASE}/secrets-${TS}"

mkdir -p "$OUT_DIR"
chmod 700 "$OUT_DIR" || true

backup_dir() {
  local name="$1"
  local src="$2"
  local dest="$OUT_DIR/${name}.tar.gz"

  if [[ ! -d "$src" ]]; then
    say "Skipping missing: $src"
    return 0
  fi

  # Avoid copying sockets/locks; keep permissions.
  tar -C "$HOME" -czf "$dest" \
    --warning=no-file-changed \
    --exclude ".gnupg/S.gpg-agent*" \
    --exclude ".gnupg/*.lock" \
    --exclude ".gnupg/random_seed" \
    "$(basename "$src")"

  chmod 600 "$dest" || true
  say "Wrote: $dest"
}

backup_dir "ssh" "$HOME/.ssh"
backup_dir "gnupg" "$HOME/.gnupg"

say ""
say "Done."
say "Store this folder somewhere safe (external drive / encrypted volume):"
say "  $OUT_DIR"


