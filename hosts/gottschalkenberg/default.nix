{ user, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./network.nix
    ../../modules/common/users.nix
    ../../profiles/nixos/homelab.nix
    ../../profiles/nixos/home-assistant-host.nix
  ];

  networking.hostName = "gottschalkenberg";
  users.users.${user}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFCbOpE20NLZKhFKY7qZWtVYQOARKs5v9nvP/ki98UI oliver@wildspitz"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9GqsSCwwBL0Upl+geKDKH3OoqFFduiwI4cYHA/DV/z oliver+bitwarden@wooding.dev"
  ];
  security.sudo.wheelNeedsPassword = false;

  home-manager.users.${user} = {
    home.username = user;
    home.homeDirectory = "/home/${user}";
    home.stateVersion = "26.05";
  };
  services.haos-vm = {
    enable = true;
    hypervisor = "qemu";
    gicVersion = 2;
    bridge = "br0";
    macAddress = "02:48:41:05:00:01";
  };

  system.stateVersion = "26.05";
}
