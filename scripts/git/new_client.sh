#!/usr/bin/env bash
set -euo pipefail

say() { printf "%s\n" "$*"; }
die() { say "ERROR: $*"; exit 1; }

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

usage() {
  cat <<EOF
Usage:
  ./scripts/git/new_client.sh --client <name> [options]

Options:
  --client <name>           Client slug (e.g. acme)
  --base-dir <path>         Base directory for projects (default: ~/Documents/Clientes)
  --email <email>           Git email for this client (required)
  --name <name>             Git user.name (default: current git global or "Caio")
  --signingkey <keyid>      GPG key id (optional)
  --provider <p>            Provider: github|bitbucket|gitlab|custom (default: github)
  --ssh-host <host-alias>   SSH Host alias to create (default: <client>-<provider>)
  --ssh-hostname <host>     SSH HostName (default by provider, e.g. github.com, bitbucket.org)
  --ssh-user <user>         SSH User (default: git)
  --direnv                  Create a .envrc in the client folder (non-secret placeholders)

What it does:
  1) Creates a client folder: <base-dir>/<client>/
  2) Creates a per-client git config at: ~/.config/git/clients/<client>.gitconfig
  3) Adds includeIf rule into ~/.gitconfig for repos under that folder
  4) Generates a dedicated SSH key in: ~/.ssh/keys/<client>_ed25519
  5) Writes SSH config entry in: ~/.ssh/config.d/<client>.conf

Note:
  This does NOT upload keys to GitHub/GitLab automatically.
EOF
}

CLIENT=""
BASE_DIR="${HOME}/Documents/Clientes"
EMAIL=""
NAME=""
SIGNINGKEY=""
PROVIDER="github"
SSH_HOST=""
SSH_HOSTNAME=""
SSH_USER="git"
DO_DIRENV=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --client) CLIENT="${2:-}"; shift 2 ;;
    --base-dir) BASE_DIR="${2:-}"; shift 2 ;;
    --email) EMAIL="${2:-}"; shift 2 ;;
    --name) NAME="${2:-}"; shift 2 ;;
    --signingkey) SIGNINGKEY="${2:-}"; shift 2 ;;
    --provider) PROVIDER="${2:-}"; shift 2 ;;
    --ssh-host) SSH_HOST="${2:-}"; shift 2 ;;
    --ssh-hostname) SSH_HOSTNAME="${2:-}"; shift 2 ;;
    --ssh-user) SSH_USER="${2:-}"; shift 2 ;;
    --direnv) DO_DIRENV=1; shift 1 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown arg: $1 (use --help)" ;;
  esac
done

[[ -n "$CLIENT" ]] || die "--client is required"
[[ -n "$EMAIL" ]] || die "--email is required"

if [[ -z "$NAME" ]]; then
  NAME="$(git config --global user.name 2>/dev/null || true)"
  NAME="${NAME:-Caio}"
fi

case "$PROVIDER" in
  github) SSH_HOSTNAME="${SSH_HOSTNAME:-github.com}" ;;
  bitbucket) SSH_HOSTNAME="${SSH_HOSTNAME:-bitbucket.org}" ;;
  gitlab) SSH_HOSTNAME="${SSH_HOSTNAME:-gitlab.com}" ;;
  custom)
    [[ -n "$SSH_HOSTNAME" ]] || die "--ssh-hostname is required when --provider custom"
    ;;
  *) die "Invalid --provider: $PROVIDER (use github|bitbucket|gitlab|custom)" ;;
esac

SSH_HOST="${SSH_HOST:-${CLIENT}-${PROVIDER}}"

CLIENT_DIR="${BASE_DIR}/${CLIENT}"
GIT_CLIENT_CFG="${HOME}/.config/git/clients/${CLIENT}.gitconfig"
SSH_KEY_DIR="${HOME}/.ssh/keys"
SSH_KEY_PATH="${SSH_KEY_DIR}/${CLIENT}_ed25519"
SSH_CONF_DIR="${HOME}/.ssh/config.d"
SSH_CONF_FILE="${SSH_CONF_DIR}/${CLIENT}.conf"

mkdir -p "$CLIENT_DIR"
mkdir -p "$(dirname "$GIT_CLIENT_CFG")"
mkdir -p "$SSH_KEY_DIR" "$SSH_CONF_DIR"
chmod 700 "${HOME}/.ssh" "$SSH_KEY_DIR" "$SSH_CONF_DIR" || true

if [[ ! -f "$GIT_CLIENT_CFG" ]]; then
  {
    echo "[user]"
    echo "  name = ${NAME}"
    echo "  email = ${EMAIL}"
    if [[ -n "$SIGNINGKEY" ]]; then
      echo "  signingkey = ${SIGNINGKEY}"
    fi
    echo ""
    echo "# Force SSH host alias for this provider (so the right key is used)"
    echo "[url \"${SSH_HOST}:\"]"
    echo "  insteadOf = git@${SSH_HOSTNAME}:"
    echo "  insteadOf = ssh://git@${SSH_HOSTNAME}/"
  } > "$GIT_CLIENT_CFG"
  say "Wrote: $GIT_CLIENT_CFG"
else
  say "Exists: $GIT_CLIENT_CFG (skipping write)"
fi

if (( DO_DIRENV )); then
  if [[ ! -f "${CLIENT_DIR}/.envrc" ]]; then
    cat > "${CLIENT_DIR}/.envrc" <<EOF
# direnv file for client: ${CLIENT}
# Put *non-secret* defaults here. For secrets, prefer 1Password/Bitwarden,
# or load from a local untracked file.
export CLIENT_SLUG="${CLIENT}"
EOF
    say "Wrote: ${CLIENT_DIR}/.envrc"
    say "Then run: (cd '${CLIENT_DIR}' && direnv allow)"
  else
    say "Exists: ${CLIENT_DIR}/.envrc (skipping write)"
  fi
fi

# Ensure ~/.gitconfig has includeIf for this client dir
GITCONFIG="${HOME}/.gitconfig"
if [[ ! -f "$GITCONFIG" ]]; then
  # If user didn't run bootstrap yet, seed it from repo git/.gitconfig
  if [[ -f "$DOTFILES_ROOT/git/.gitconfig" ]]; then
    cp "$DOTFILES_ROOT/git/.gitconfig" "$GITCONFIG"
  else
    touch "$GITCONFIG"
  fi
fi

INCLUDE_SNIPPET=$(cat <<EOF

[includeIf "gitdir:${CLIENT_DIR}/"]
  path = ${GIT_CLIENT_CFG}
EOF
)

if ! grep -q "includeIf \\\"gitdir:${CLIENT_DIR}/\\\"" "$GITCONFIG" 2>/dev/null; then
  printf "%s\n" "$INCLUDE_SNIPPET" >> "$GITCONFIG"
  say "Updated: $GITCONFIG (added includeIf for $CLIENT_DIR/)"
else
  say "includeIf already present in $GITCONFIG"
fi

# Create SSH key (if missing)
if [[ ! -f "${SSH_KEY_PATH}" ]]; then
  ssh-keygen -t ed25519 -C "${EMAIL}" -f "${SSH_KEY_PATH}" -N ""
  chmod 600 "${SSH_KEY_PATH}" || true
  chmod 644 "${SSH_KEY_PATH}.pub" || true
  say "Generated SSH key: ${SSH_KEY_PATH} (+ .pub)"
else
  say "SSH key exists: ${SSH_KEY_PATH}"
fi

# Write SSH config entry (idempotent by file)
if [[ ! -f "$SSH_CONF_FILE" ]]; then
  {
    echo "Host ${SSH_HOST}"
    echo "  HostName ${SSH_HOSTNAME}"
    echo "  User ${SSH_USER}"
    echo "  IdentityFile ${SSH_KEY_PATH}"
    echo "  IdentitiesOnly yes"
  } > "$SSH_CONF_FILE"
  chmod 600 "$SSH_CONF_FILE" || true
  say "Wrote: $SSH_CONF_FILE"
else
  say "Exists: $SSH_CONF_FILE (skipping write)"
fi

say ""
say "Next steps:"
say "1) Add this public key to your Git provider:"
say "   cat '${SSH_KEY_PATH}.pub'"
say "2) Clone repos using the host alias:"
case "$PROVIDER" in
  github|gitlab) say "   git clone ${SSH_HOST}:ORG/REPO.git" ;;
  bitbucket) say "   git clone ${SSH_HOST}:WORKSPACE/REPO.git" ;;
  custom) say "   git clone ${SSH_HOST}:ORG/REPO.git" ;;
esac


