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

source $ZSH/oh-my-zsh.sh

# Initialize Oh My Posh
eval "$(oh-my-posh init zsh --config $HOME/.poshthemes/powerlevel10k_modern.omp.json)"
