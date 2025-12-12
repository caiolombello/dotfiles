#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { say "ERROR: $*"; exit 1; }

usage() {
  cat <<EOF
Usage:
  ./scripts/git/new_project.sh --client <client> --project <name> [options]

Options:
  --base-dir <path>     Base directory for clients (default: ~/Documents/Clientes)
  --remote <org/repo>   If set, adds origin remote using SSH host alias
  --provider <p>        Provider: github|bitbucket|gitlab|custom (default: github)
  --ssh-host <alias>    SSH host alias (default: <client>-<provider>)
  --no-readme           Do not create README.md

Examples:
  new_project --client acme --project payments
  new_project --client acme --project payments --remote acme/payments-api
EOF
}

CLIENT=""
PROJECT=""
BASE_DIR="${HOME}/Documents/Clientes"
REMOTE=""
PROVIDER="github"
SSH_HOST=""
NO_README=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --client) CLIENT="${2:-}"; shift 2 ;;
    --project) PROJECT="${2:-}"; shift 2 ;;
    --base-dir) BASE_DIR="${2:-}"; shift 2 ;;
    --remote) REMOTE="${2:-}"; shift 2 ;;
    --provider) PROVIDER="${2:-}"; shift 2 ;;
    --ssh-host) SSH_HOST="${2:-}"; shift 2 ;;
    --no-readme) NO_README=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1 (use --help)" ;;
  esac
done

[[ -n "$CLIENT" ]] || die "--client is required"
[[ -n "$PROJECT" ]] || die "--project is required"

SSH_HOST="${SSH_HOST:-${CLIENT}-${PROVIDER}}"

CLIENT_DIR="${BASE_DIR}/${CLIENT}"
PROJ_DIR="${CLIENT_DIR}/${PROJECT}"

mkdir -p "$PROJ_DIR"
cd "$PROJ_DIR"

if [[ ! -d .git ]]; then
  git init
  git branch -M main 2>/dev/null || true
fi

if (( ! NO_README )) && [[ ! -f README.md ]]; then
  cat > README.md <<EOF
# ${PROJECT}

Client: ${CLIENT}
EOF
  git add README.md >/dev/null 2>&1 || true
fi

if [[ -n "$REMOTE" ]]; then
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "${SSH_HOST}:${REMOTE}.git"
  fi
fi

say "Project ready: $PROJ_DIR"
say "Git identity should be auto-selected by includeIf for: $CLIENT_DIR/"
if [[ -n "$REMOTE" ]]; then
  say "Origin: $(git remote get-url origin 2>/dev/null || true)"
fi


