# nix-homebrew wiring for all macOS hosts
#
# Declares the homebrew-core and homebrew-cask taps explicitly so that
# nix-homebrew can manage them without network access at activation time,
# and sets homebrew.taps to match.

{
  user,
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];
  nix-homebrew = {
    inherit user;
    enable = true;

    # declare taps explicitly
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };

    # disable imperatively added taps
    mutableTaps = false;
  };

  # set homebrew.taps to the declared nix-homebrew taps
  homebrew.taps = builtins.attrNames config.nix-homebrew.taps;
}
