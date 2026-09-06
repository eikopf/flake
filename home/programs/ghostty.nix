{ pkgs, ... }:
let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  programs.ghostty = {
    enable = true;
    package = if isDarwin then null else pkgs.ghostty;

    settings = {
      theme = "Alabaster";
      font-family = "Berkeley Mono";
      mouse-hide-while-typing = true;
      app-notifications = "no-clipboard-copy";
      progress-style = false;

      # BUG: this seems not to work on macOS for some reason
      cursor-style = "block";

      # gui
      title = " ";
      window-title-font-family = "Berkeley Mono";
      window-theme = "light";
      window-padding-x = 5;
      window-save-state = "always";

      # macos
      macos-titlebar-style = "hidden";
      macos-titlebar-proxy-icon = "hidden";
      macos-option-as-alt = true;
    };
  };
}
