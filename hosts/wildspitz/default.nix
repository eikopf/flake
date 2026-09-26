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
    ./wildspitzli.nix
    ../../modules/nixos/uefi.nix
    ../../modules/nixos/prefer-wired.nix
    ../../profiles/nixos/workstation.nix
    ../../profiles/nixos/homelab.nix
    ../../modules/nixos/desktops/sway.nix
    ../../modules/nixos/services/tailscale-exit-node.nix
  ];
  networking.hostName = "wildspitz";
  networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
  systemd.network.wait-online.enable = false;
  boot.initrd.systemd.network.wait-online.enable = false;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelParams = [ "video=DP-1:e" ];
  home-manager.users.${user}.imports = [ ./home.nix ];
  # Compatibility baseline: preserve across upgrades and refactors.
  system.stateVersion = "25.11";
}
