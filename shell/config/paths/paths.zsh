# Helpers to manage PATH without duplicates
path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_append() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$PATH:$1" ;;
  esac
}

# System paths
path_append "/usr/sbin"
path_prepend "$HOME/.local/bin"

# Go
export GOPATH="${GOPATH:-$HOME/go}"
path_append "/usr/local/go/bin"
path_append "$GOPATH/bin"

# Rust (optional)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Node.js (nvm, optional)
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# .NET
path_append "$HOME/.dotnet"
path_append "$HOME/.dotnet/tools"

# Bun (optional)
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
[ -d "$BUN_INSTALL/bin" ] && path_prepend "$BUN_INSTALL/bin"

# PNPM
export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
[ -d "$PNPM_HOME" ] && path_prepend "$PNPM_HOME"

# Custom bin path
[ -d "$HOME/bin" ] && path_prepend "$HOME/bin"

export PATH
