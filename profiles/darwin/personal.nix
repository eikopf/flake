{
  pkgs,
  lib,
  user,
  ...
}:
{
  imports = [
    ../common/personal.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/aerospace.nix
    ../../modules/darwin/tailscale.nix
  ];
  users.knownUsers = [ user ];
  users.users.${user}.uid = lib.mkDefault 501;
  system.primaryUser = user;
  home-manager.users.${user} = {
    imports = [
      ../../home/profiles/desktop.nix
      ../../home/profiles/development.nix
    ];
    home.packages = with pkgs; [
      orbstack
      monitorcontrol
      hledger
    ];
  };
  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv"; # use columns in Finder by default
    NSGlobalDomain.AppleICUForce24HourTime = true;
    NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  };
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # Keep the daemon package explicit; tools such as nixd rely
  # on this setting being accurate to work correctly
  nix.package = pkgs.lix;

  homebrew = {
    enable = true;
    global.autoUpdate = false;

    casks = [
      # coding agents
      "claude-code"
      "codex"

      "ghostty" # terminal
    ];
  };

  # The application firewall shows an "allow incoming connections?" dialog on
  # the console for unsigned binaries (all nix store binaries) and silently
  # drops their inbound packets until it's clicked — which breaks mosh-server
  # exactly when connecting remotely with nobody at the screen. Clicking
  # "Allow" only whitelists one store path, so it breaks again on every mosh
  # update; instead, re-register the live path on each activation.
  system.activationScripts.postActivation.text = ''
    fw=/usr/libexec/ApplicationFirewall/socketfilterfw
    $fw --add ${pkgs.mosh}/bin/mosh-server >/dev/null
    $fw --unblockapp ${pkgs.mosh}/bin/mosh-server >/dev/null
  '';
}
