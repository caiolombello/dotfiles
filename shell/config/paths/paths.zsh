# System paths
export PATH=$PATH:/usr/sbin:$HOME/.local/bin

# Go paths
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$HOME/go/bin

# Rust paths
. "$HOME/.cargo/env"

# Node.js paths
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# .NET paths
export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools

# Bun paths
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PNPM paths
export PNPM_HOME="/home/caio/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Custom bin path
export PATH=/home/caio/bin:$PATH
