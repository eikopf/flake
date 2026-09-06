{ config, ... }:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh" ];
  };
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
}
