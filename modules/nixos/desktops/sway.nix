{ pkgs, user, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  # graphics
  hardware.graphics.enable = true;

  # login manager
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --asterisks --cmd sway";
        user = "greeter";
      };
    };
  };

  # keychain — needed for VSCode (and other apps) to store secrets securely.
  # PAM integration ensures the keyring is unlocked automatically on login.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  # gpg-agent (below) is the SSH agent; prevent gcr from competing for SSH_AUTH_SOCK.
  services.gnome.gcr-ssh-agent.enable = false;

  # xdg-desktop-portal — required for screen sharing, file pickers, and
  # PipeWire-based capture under Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Force native Wayland rendering to avoid blurriness from XWayland upscaling
  # under fractional scaling.
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1"; # Firefox / Thunderbird
    ELECTRON_OZONE_PLATFORM_HINT = "auto"; # Electron 22+ apps
  };

  environment.systemPackages = with pkgs; [
    swaylock
    grim
    slurp
    wl-clipboard
  ];
  home-manager.users.${user} = {
    imports = [
      ../../../home/desktops/sway/sway.nix
      ../../../home/desktops/sway/swayidle.nix
      ../../../home/desktops/sway/waybar.nix
      ../../../home/desktops/sway/rofi.nix
      ../../../home/desktops/sway/desktop-theme.nix
    ];
    home.packages = [ pkgs.gcr ];
    services.gpg-agent = {
      enableSshSupport = true;
      pinentry.package = pkgs.pinentry-gnome3;
    };
  };
}
