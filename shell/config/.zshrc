setopt no_beep
setopt auto_cd

# Where this dotfiles Zsh config lives (works even when ~/.zshrc is a symlink)
# - ${(%):-%x} is the currently-sourced file path in zsh
export DOTFILES_ZSH_DIR="${DOTFILES_ZSH_DIR:-${${(%):-%x}:A:h}}"

# Paths
source "$DOTFILES_ZSH_DIR/paths/paths.zsh"

# direnv (optional)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Theme/prompt (Oh My Zsh + Oh My Posh)
source "$DOTFILES_ZSH_DIR/theme/theme.zsh"

# Aliases
setopt null_glob
for file in "$DOTFILES_ZSH_DIR/aliases/"*.zsh; do
  source "$file"
done

# Functions
for file in "$DOTFILES_ZSH_DIR/functions/"*.zsh; do
  source "$file"
done

# Local env (optional)
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

