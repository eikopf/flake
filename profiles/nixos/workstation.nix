{ user, ... }:
{
  imports = [
    ../common/personal.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/fonts.nix
  ];
  networking.networkmanager.enable = true;
  services.resolved.enable = true;
  services.udisks2.enable = true;
  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  hardware.graphics.enable = true;
  users.users.${user}.extraGroups = [ "networkmanager" ];
  home-manager.users.${user} = {
    imports = [
      ../../home/profiles/desktop.nix
      ../../home/profiles/development.nix
    ];
    programs.firefox.enable = true;
    programs.anki.enable = true;
    programs.vscode.enable = true;
  };
}
