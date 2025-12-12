# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
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

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Initialize Oh My Posh
if command -v oh-my-posh >/dev/null 2>&1 && [ -f "$HOME/.poshthemes/powerlevel10k_modern.omp.json" ]; then
  eval "$(oh-my-posh init zsh --config "$HOME/.poshthemes/powerlevel10k_modern.omp.json")"
fi
