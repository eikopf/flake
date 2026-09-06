{ user, ... }:
{
  imports = [ ../../profiles/darwin/personal.nix ];
  networking = {
    computerName = "Pilatus";
    hostName = "pilatus";
  };
  home-manager.users.${user}.home.stateVersion = "26.05";
  system.stateVersion = 5;
}
