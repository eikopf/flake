{ config, lib, ... }:
{
  services.tailscale = {
    enable = lib.mkDefault true;
  };

  # Tailscale SSH. On NixOS this is services.tailscale.extraSetFlags, which
  # re-asserts the flag on every tailscaled start; nix-darwin's module has no
  # equivalent, so do the same by hand. tailscaled's local API may not be
  # ready right at boot; wait for it.
  launchd.daemons.tailscale-set = lib.mkIf config.services.tailscale.enable {
    script =
      let
        tailscale = lib.getExe' config.services.tailscale.package "tailscale";
      in
      ''
        until ${tailscale} status --peers=false >/dev/null 2>&1; do sleep 1; done
        ${tailscale} set --ssh
      '';
    serviceConfig.RunAtLoad = true;
  };

}
