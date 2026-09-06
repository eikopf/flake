{ ... }:
{
  imports = [
    ./nix.nix
    ./shell.nix
  ];
  nixpkgs.config.allowUnfree = true;
}
