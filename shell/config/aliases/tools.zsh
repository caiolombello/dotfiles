# Modern tool aliases
alias ls="exa --group-directories-first --icons"
alias ll="exa -l --group-directories-first --icons"
alias grep="rg"
alias rgf="rg --files"
alias find="fd"
alias cat="bat --style=plain --paging=never --decorations=never"
alias sed="sd"
alias top="btm"
alias tailf="hwatch"
alias df="dysk"
alias gpgr='gpgconf --kill gpg-agent && gpgconf --launch gpg-agent && export GPG_TTY=$(tty)'
