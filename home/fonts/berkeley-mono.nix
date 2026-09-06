{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  fontDirectory =
    if pkgs.stdenv.isDarwin then
      "${config.home.homeDirectory}/Library/Fonts"
    else
      "${config.xdg.dataHome}/fonts/berkeley-mono";
  encryptedFonts = ../../secrets/fonts;
  fontFiles = builtins.attrNames (builtins.readDir encryptedFonts);
in
{
  imports = [ inputs.agenix.homeManagerModules.default ];

  # Decrypt into the actual user font directory at login. Only ciphertext is
  # copied into the Nix store; font discovery does not depend on a runtime symlink.
  age.secrets = lib.listToAttrs (
    map (
      name:
      let
        fontName = lib.removeSuffix ".age" name;
      in
      lib.nameValuePair "berkeley-mono/${fontName}" {
        file = encryptedFonts + "/${name}";
        path = "${fontDirectory}/${fontName}";
        symlink = false;
        mode = "0400";
      }
    ) fontFiles
  );

  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.isLinux true;
  systemd.user.services.agenix = lib.mkIf pkgs.stdenv.isLinux {
    Service.ExecStartPost = toString (
      pkgs.writeShellScript "refresh-private-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-cache -f ${lib.escapeShellArg fontDirectory}
      ''
    );
  };
}
