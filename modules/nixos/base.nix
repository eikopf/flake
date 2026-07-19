{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/boot".options = [ "umask=0077" ];

  networking.networkmanager.enable = true;
  # local caching DNS resolver with DNSSEC and mDNS support
  services.resolved.enable = true;

  # allow regular users to mount removable drives
  services.udisks2.enable = true;

  # compressed in-RAM swap — protects against OOM on long-running machines
  zramSwap.enable = true;

  # nix-ld — allows running unpackaged dynamic binaries
  programs.nix-ld.enable = true;

  # dconf — required for GTK apps to persist settings
  programs.dconf.enable = true;

  # printing
  services.printing.enable = true;

  # mDNS — enables .local hostname resolution and network printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  nixpkgs.config.allowUnfree = true;
}
