{ pkgs, ... }:
{
  imports = [ ../../home/programs/thunderbird.nix ];
  home.stateVersion = "26.05";
  wayland.windowManager.sway.config.output."DP-1".scale = "1.5";
  systemd.user.services.swaybg.Service.ExecStart =
    "${pkgs.swaybg}/bin/swaybg -o DP-1 -i ${../../wallpaper/gris.jpg} -m fill";
}
