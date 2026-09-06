{ pkgs, ... }:
{
  programs.fish.enable = true;
  # Everyday tools available in administrative and personal shells on every host.
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    tree
    less
    file
    jq
    ripgrep
    fd
    fzf
    tmux
    htop
    rsync
    unzip
    zip
    gnused
    gnutar
  ];
  environment.variables.EDITOR = "vim";
}
