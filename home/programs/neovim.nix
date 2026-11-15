{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neovim
    tree-sitter
    stdenv.cc
    curl
    gnutar
    ripgrep
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
