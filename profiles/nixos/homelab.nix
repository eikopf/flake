{ ... }:
{
  imports = [ ../../modules/nixos/services/tailscale.nix ];
  networking.nftables.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

}
