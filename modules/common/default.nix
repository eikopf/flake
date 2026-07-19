{ pkgs, ... }:
{
  imports = [
    ./nix.nix
    ./shell.nix
    ./users.nix
  ];

  # base packages installed by all hosts
  environment.systemPackages = with pkgs; [
    git-extras
    gh
    gnupg
    readline
    rlwrap
    vim
    wget
    curl
    hyperfine
    just
  ];
}
