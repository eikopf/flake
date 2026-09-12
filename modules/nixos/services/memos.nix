{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.personal.services.memos;
in
{
  imports = [ inputs.quadlet-nix.nixosModules.quadlet ];

  options.personal.services.memos = {
    enable = lib.mkEnableOption "the Memos note-taking service";
    statePath = lib.mkOption {
      type = lib.types.addCheck lib.types.str (s: lib.hasPrefix "/" s);
      default = "/var/lib/memos";
      description = "Directory containing the Memos SQLite database and uploads.";
    };
    tailscaleServe = lib.mkEnableOption "publishing Memos as a Tailscale Service";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale.enable = lib.mkIf cfg.tailscaleServe true;

    virtualisation.quadlet.containers.memos.containerConfig = {
      image = "docker.io/neosmemo/memos:0.30.0@sha256:71a5b4738d1bed96e92112004054f0888e92791b64eb78afd79077c96e6f9327";
      environments = {
        MEMOS_ADDR = "0.0.0.0";
        MEMOS_PORT = "5230";
        MEMOS_DATA = "/var/opt/memos";
        MEMOS_DRIVER = "sqlite";
        # In 0.30, leaving this unset keeps anonymous instance access disabled.
        MEMOS_INSTANCE_URL = "";
      };
      volumes = [ "${cfg.statePath}:/var/opt/memos" ];
      publishPorts = [ "127.0.0.1:5230:5230" ];
    };

    systemd.tmpfiles.rules = [ "d ${cfg.statePath} 0700 root root -" ];

    # Create svc:memos, approve the host, and grant access to port 443 in
    # the Tailscale admin console, as for the other homelab services.
    systemd.services.tailscale-serve-memos = lib.mkIf cfg.tailscaleServe {
      description = "Advertise Memos as Tailscale Service svc:memos";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = "until ${config.services.tailscale.package}/bin/tailscale status --peers=false >/dev/null 2>&1; do sleep 1; done";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:memos --yes --https=443 127.0.0.1:5230";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve clear svc:memos";
      };
    };
  };
}
