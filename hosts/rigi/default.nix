# NOTE: this config evaluates cleanly (covered by flake checks) but hasn't
# been booted recently — hardware behaviour is untested

{
  config,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # networking
  networking.hostName = "rigi";

  # X11
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.variant = "mac";

  # Plasma 6
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # graphics
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = true;
  };

  # install firefox
  programs.firefox.enable = true;

  # release at first install — do not change
  system.stateVersion = "24.11";
}
