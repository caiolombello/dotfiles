#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$DOTFILES_ROOT/vscode/extensions.txt"

try_export() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    return 1
  fi

  # Some setups have "code" pointing to snap; in that case this won't work.
  if "$cmd" --help 2>/dev/null | grep -q -- '--list-extensions'; then
    "$cmd" --list-extensions --show-versions | sort > "$OUT"
    return 0
  fi

  return 1
}

if try_export cursor; then
  echo "Exported extensions using: cursor -> $OUT"
  exit 0
fi

if try_export code; then
  echo "Exported extensions using: code -> $OUT"
  exit 0
fi

if try_export codium; then
  echo "Exported extensions using: codium -> $OUT"
  exit 0
fi

echo "Could not export extensions (no compatible CLI found)."
echo "Tried: cursor, code, codium"
exit 1


