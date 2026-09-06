{
  config,
  pkgs,
  lib,
  ...
}:
{
  xdg = {
    enable = true;
    userDirs = lib.mkIf pkgs.stdenv.isLinux {
      enable = true;
      createDirectories = true;
      # export XDG_*_DIR variables into the session (set explicitly because
      # the home-manager default flips to false at stateVersion 26.05)
      setSessionVariables = true;
      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = "${config.home.homeDirectory}/music";
      pictures = "${config.home.homeDirectory}/pictures";
      projects = "${config.home.homeDirectory}/projects";
      publicShare = "${config.home.homeDirectory}/public";
      templates = "${config.home.homeDirectory}/templates";
      videos = "${config.home.homeDirectory}/videos";
    };
  };
}
