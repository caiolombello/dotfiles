#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { say "ERROR: $*"; exit 1; }

IN_DIR="${1:-}"
[[ -n "$IN_DIR" ]] || die "Usage: ./scripts/backup/import_secrets.sh <backup-folder>"
[[ -d "$IN_DIR" ]] || die "Folder not found: $IN_DIR"

restore_tar() {
  local name="$1"
  local tarfile="$IN_DIR/${name}.tar.gz"
  [[ -f "$tarfile" ]] || { say "Skipping missing: $tarfile"; return 0; }

  say "Restoring: $tarfile"
  tar -C "$HOME" -xzf "$tarfile"
}

restore_tar "ssh"
restore_tar "gnupg"

# Fix perms (best-effort)
if [[ -d "$HOME/.ssh" ]]; then
  chmod 700 "$HOME/.ssh" || true
  find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
  find "$HOME/.ssh" -type f ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
fi

if [[ -d "$HOME/.gnupg" ]]; then
  chmod 700 "$HOME/.gnupg" || true
  find "$HOME/.gnupg" -type f -exec chmod 600 {} \; 2>/dev/null || true
fi

say "Done. You may need to restart gpg-agent:"
say "  gpgconf --kill gpg-agent && gpgconf --launch gpg-agent"


