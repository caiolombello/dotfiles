# Git aliases
if command -v delta >/dev/null 2>&1; then
  alias gd="delta"
else
  alias gd="git diff"
fi
alias gs="git status"
alias gca="git commit --amend"
alias glog="git log --graph --oneline --decorate --all --pretty=format:'%C(blue)%h %C(red)%d %C(white)%s - %C(cyan)%cn, %C(green)%cr'"

