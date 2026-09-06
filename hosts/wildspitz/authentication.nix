{
  pkgs,
  user,
  inputs,
  ...
}:
{
  # Allow the registered FIDO/U2F token to satisfy PAM authentication on its
  # own. Password authentication remains available as the fallback.
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
      authfile = pkgs.writeText "u2f-mappings" ''
        ${user}:i8+j14o7fU2/ykOH4PCztfSxTHbbHtQNwsXzmHeyT5fvLW3Eek6/rlJqm8Lzc2/XQ/O50uYmiDAUcfNp93FAIg==,C/ArTu2/V6JUPoMUQYMbQrJSVK4uoL44jCMwGT7pK8CF9u3vtM9mXiR35yzKgH6tC+yOwoi9ZuZeF+YHn6hhuQ==,es256,+presence
      '';
    };
  };

  # Require PIN verification when the YubiKey is used for interactive desktop
  # access. Other PAM consumers (such as sudo) continue to require only touch.
  security.pam.services.greetd.rules.auth.u2f.settings = {
    pinverification = 1;
    userverification = 0;
  };
  security.pam.services.swaylock.rules.auth.u2f.settings = {
    pinverification = 1;
    userverification = 0;
  };

  # age-plugin-yubikey uses the YubiKey's PIV applet through PC/SC.
  services.pcscd.enable = true;

  environment.systemPackages = [
    pkgs.age-plugin-yubikey
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
