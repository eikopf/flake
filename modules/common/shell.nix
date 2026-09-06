{ pkgs, ... }:
{
  programs.fish.enable = true;
  environment.systemPackages = [
    pkgs.vim
    pkgs.curl
  ];
  environment.variables.EDITOR = "vim";
}
