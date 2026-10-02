# Optional Home Manager module draft. No installation or activation performed.
# The approved host configuration must supply home.username,
# home.homeDirectory and home.stateVersion before evaluation/activation.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    zsh
    vim
    tmux
    ripgrep
    jq
    fzf
  ];

  home.file.".vimrc".source = ../files/vimrc;
  home.file.".zshrc".source = ../files/zshrc;
  home.file.".gitconfig".source = ../files/gitconfig;
}
