# common nix configuration

{ ... }:
{
  # enable flakes and modern nix command
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # automatically deduplicate store paths
  nix.optimise.automatic = true;

  # automate garbage collection
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  # set trusted users
  nix.settings.trusted-users = [
    "root"
  ];
}
