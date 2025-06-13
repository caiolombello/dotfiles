# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"  # Using a simple theme since we'll use Oh My Posh

# Auto update behavior
zstyle ':omz:update' mode auto      # update automatically without asking

# Which plugins would you like to load?
plugins=(
  git
  docker
  kubectl
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  ansible
  terraform
  aws
  helm
)

source $ZSH/oh-my-zsh.sh

# Initialize Oh My Posh
eval "$(oh-my-posh init zsh --config $HOME/.poshthemes/powerlevel10k_modern.omp.json)"

# Load theme configuration
source "$(dirname "$0")/theme/theme.zsh"

# Load path configurations
source "$(dirname "$0")/paths/paths.zsh"

# Load aliases
for file in "$(dirname "$0")/aliases/"*.zsh; do
    source "$file"
done

# Load functions
for file in "$(dirname "$0")/functions/"*.zsh; do
    source "$file"
done

# Load local environment if it exists
[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"

