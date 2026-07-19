{ user, ... }:
{
  imports = [
    ./anki.nix
    ./atuin.nix
    ./delta.nix
    ./direnv.nix
    ./eza.nix
    ./firefox.nix
    ./fish.nix
    ./ghostty.nix
    ./git.nix
    ./gpg.nix
    ./hyfetch.nix
    ./jujutsu.nix
    ./kitty.nix
    ./neovide.nix
    ./neovim.nix
    ./starship.nix
    ./vscode.nix
    ./xdg.nix
    ./zoxide.nix
  ];

  home.username = user;
  # Compatibility version from the first Home Manager installation. Do not
  # update this when updating Home Manager; review migrations individually.
  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
