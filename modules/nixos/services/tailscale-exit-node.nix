{ ... }:
{
  imports = [ ./tailscale.nix ];
  services.tailscale = {
    useRoutingFeatures = "server";
    extraSetFlags = [ "--advertise-exit-node" ];
  };
}
