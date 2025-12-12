# Modern tool aliases (portable across distros)
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --group-directories-first --icons"
  alias ll="eza -l --group-directories-first --icons"
elif command -v exa >/dev/null 2>&1; then
  alias ls="exa --group-directories-first --icons"
  alias ll="exa -l --group-directories-first --icons"
fi

if command -v rg >/dev/null 2>&1; then
  alias grep="rg"
  alias rgf="rg --files"
fi

if command -v fd >/dev/null 2>&1; then
  alias find="fd"
elif command -v fdfind >/dev/null 2>&1; then
  alias find="fdfind"
fi

if command -v bat >/dev/null 2>&1; then
  alias cat="bat --style=plain --paging=never --decorations=never"
elif command -v batcat >/dev/null 2>&1; then
  alias cat="batcat --style=plain --paging=never --decorations=never"
fi

command -v sd >/dev/null 2>&1 && alias sed="sd"
command -v btm >/dev/null 2>&1 && alias top="btm"
command -v hwatch >/dev/null 2>&1 && alias tailf="hwatch"
command -v dysk >/dev/null 2>&1 && alias df="dysk"

alias gpgr='gpgconf --kill gpg-agent && gpgconf --launch gpg-agent && export GPG_TTY=$(tty)'
