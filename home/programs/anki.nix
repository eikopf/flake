{ lib, pkgs, ... }:
{
  programs.anki = {
    enable = lib.mkDefault false;

    addons = with pkgs.ankiAddons; [
      anki-connect
      review-heatmap
    ];
  };
}
