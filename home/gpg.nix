{ lib, ... }:
{
  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    extraConfig = lib.concatLines [
      "allow-preset-passphrase"
    ];
  };
}
