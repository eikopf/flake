{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  kernelPkgs = import inputs.nixpkgs-pi {
    localSystem = "x86_64-linux";
    crossSystem = "aarch64-linux";
  };
in
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-5
    "${inputs.nixpkgs-pi}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.initrd.systemd.tpm2.enable = false;
  boot.kernelPackages = pkgs.linuxPackagesFor (
    kernelPkgs.callPackage "${inputs.nixos-hardware}/raspberry-pi/common/kernel.nix" {
      rpiVersion = 5;
    }
  );
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllHardware = lib.mkForce false;
  hardware.raspberry-pi.firmware = {
    enable = true;
    uboot.enable = true;
  };
  sdImage.compressImage = true;
  sdImage.firmwareSize = 128;
  image.baseName = "gottschalkenberg-nixos";
}
