{ lib, pkgs, ... }:
let
  alabaster = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
    mktplcRef = {
      publisher = "tonsky";
      name = "theme-alabaster";
      version = "0.2.9";
      sha256 = "0vi6i9xwd440hn61ql7rgxgnm17ip3vfs0hbqjh4la9jj0hdgfyw";
    };
  };
in
{
  programs.vscode = {
    enable = lib.mkDefault false;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      vscodevim.vim
      alabaster
    ];
  };
}
