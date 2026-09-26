# a virtual tailscale identity providing homelab services
{ config, user, ... }:
{
  imports = [ ../../modules/nixos/services/library.nix ];

  personal.services.library = {
    enable = true;
    owner = user;
    group = "users";
    libraryPath = "${config.users.users.${user}.home}/documents/library";
    ingestPath = "${config.users.users.${user}.home}/documents/library-ingest";
    secretFile = ../../secrets/grimmory.env.age;
    openFirewall = true; # KOReader needs direct LAN access.
    tailscaleServe = true;
    tailscaleHostname = "wildspitzli";
  };
}
