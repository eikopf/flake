{
  lib,
  pkgs,
  ...
}:
let
  # Thunderbird creates an empty ~/Thunderbird directory on every startup (a
  # side-effect of it initialising its default profile-root path), even though
  # all real data lives in ~/.thunderbird.  This wrapper runs the real binary
  # and then removes the empty directory once Thunderbird exits, keeping ~ tidy.
  thunderbird = pkgs.symlinkJoin {
    name = "thunderbird";
    paths = [ pkgs.thunderbird ];
    postBuild =
      let
        script = pkgs.writeShellScript "thunderbird" ''
          ${lib.getExe pkgs.thunderbird} "$@"
          _status=$?
          rmdir "$HOME/Thunderbird" "$HOME/thunderbird" 2>/dev/null || true
          exit "$_status"
        '';
      in
      ''
        rm "$out/bin/thunderbird"
        ln -s ${script} "$out/bin/thunderbird"
      '';
  };
in
{
  home.packages = [
    thunderbird # wrapped to suppress the spurious ~/Thunderbird directory
  ];
}
