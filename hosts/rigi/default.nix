# NOTE: this config evaluates cleanly (covered by flake checks) but hasn't
# been booted recently — hardware behaviour is untested

{
  config,
  user,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/uefi.nix
    ../../profiles/nixos/workstation.nix
    ../../modules/nixos/desktops/plasma.nix
  ];

  # networking
  networking.hostName = "rigi";

  # X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "mac";

  # graphics
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true;
  };

  home-manager.users.${user}.home.stateVersion = "26.05";

  # release at first install — do not change
  system.stateVersion = "24.11";
}
