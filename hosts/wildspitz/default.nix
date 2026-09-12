{
  config,
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./authentication.nix
    ../../modules/nixos/uefi.nix
    ../../modules/nixos/prefer-wired.nix
    ../../profiles/nixos/workstation.nix
    ../../profiles/nixos/homelab.nix
    ../../modules/nixos/desktops/sway.nix
    ../../modules/nixos/services/library.nix
    ../../modules/nixos/services/memos.nix
    ../../modules/nixos/services/tailscale-exit-node.nix
  ];
  networking.hostName = "wildspitz";
  # Existing tailnet-wide access policy; other hosts need not grant this.
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [ "video=DP-1:e" ];
  home-manager.users.${user}.imports = [ ./home.nix ];
  personal.services.library = {
    enable = true;
    owner = user;
    group = "users";
    libraryPath = "${config.users.users.${user}.home}/documents/library";
    ingestPath = "${config.users.users.${user}.home}/documents/library-ingest";
    secretFile = ../../secrets/grimmory.env.age;
    openFirewall = true; # KOReader needs direct LAN access.
    tailscaleServe = true;
  };
  personal.services.memos = {
    enable = true;
    tailscaleServe = true;
  };
  # Compatibility baseline: preserve across upgrades and refactors.
  system.stateVersion = "25.11";
}
