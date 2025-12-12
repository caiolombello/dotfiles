# Kubernetes aliases
alias ctx='kubectx'
alias ns='kubens'
alias contexts='kubectl config get-contexts'
alias wk="watch kubectl"
alias events="kubectl get events --sort-by=.metadata.creationTimestamp"
alias kpf='kubectl port-forward --address 0.0.0.0'

# Use kubecolor instead of kubectl (optional)
if command -v kubectl >/dev/null 2>&1; then
  source <(command kubectl completion zsh)
fi

if command -v kubecolor >/dev/null 2>&1; then
  alias kubectl=kubecolor
  compdef kubecolor=kubectl
  export KUBECOLOR_PRESET="protanopia-dark"
fi
