# Kubernetes aliases
alias ctx='kubectx'
alias ns='kubens'
alias contexts='kubectl config get-contexts'
alias wk="watch kubectl"
alias events="kubectl get events --sort-by=.metadata.creationTimestamp"
alias kpf='kubectl port-forward --address 0.0.0.0'

# Use kubecolor instead of kubectl
alias kubectl=kubecolor
source <(kubectl completion zsh)
compdef kubecolor=kubectl

export KUBECOLOR_PRESET="protanopia-dark"
