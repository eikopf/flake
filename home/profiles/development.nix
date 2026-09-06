{ pkgs, ... }:
{
  # Tools for working on this flake and entering project-owned environments.
  home.packages = with pkgs; [
    nixd
    nixfmt
    devenv
  ];
}
