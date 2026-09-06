{ identity, pkgs, ... }:
{
  imports = [
    ../programs/atuin.nix
    ../programs/delta.nix
    ../programs/direnv.nix
    ../programs/eza.nix
    ../programs/fish.nix
    ../programs/git.nix
    ../programs/gpg.nix
    ../programs/hyfetch.nix
    ../programs/jujutsu.nix
    ../programs/neovim.nix
    ../programs/starship.nix
    ../programs/xdg.nix
    ../programs/zoxide.nix
  ];
  home.username = identity.username;
  programs.home-manager.enable = true;
  home.packages = with pkgs; [
    git-extras
    gh
    tlrc
    just
    mosh
  ];
}
