# user configuration for both NixOS and macOS hosts

{
  identity,
  pkgs,
  lib,
  ...
}:
let
  user = identity.username;
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  users.users.${user} = {
    description = identity.fullName;
    home = if isDarwin then "/Users/${user}" else "/home/${user}";
    shell = pkgs.fish;
  }
  // lib.optionalAttrs isLinux {
    uid = identity.linuxUid;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    isNormalUser = true;
  };
}
