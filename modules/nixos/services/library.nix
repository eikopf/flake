# Library workload: storage and identity are assigned by the deploying host.
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.personal.services.library;
  absolutePath = lib.types.addCheck lib.types.str (s: lib.hasPrefix "/" s);
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.quadlet-nix.nixosModules.quadlet
  ];
  options.personal.services.library = {
    enable = lib.mkEnableOption "the Grimmory, MariaDB and Shelfmark library services";
    owner = lib.mkOption {
      type = lib.types.str;
      description = "Existing account owning library and service data.";
    };
    group = lib.mkOption {
      type = lib.types.str;
      description = "Existing group owning library and service data.";
    };
    libraryPath = lib.mkOption {
      type = absolutePath;
      description = "Existing book library directory.";
    };
    ingestPath = lib.mkOption {
      type = absolutePath;
      description = "Directory for Shelfmark downloads and Grimmory imports.";
    };
    grimmoryStatePath = lib.mkOption {
      type = absolutePath;
      default = "/var/lib/grimmory";
      description = "Grimmory and MariaDB state directory.";
    };
    shelfmarkStatePath = lib.mkOption {
      type = absolutePath;
      default = "/var/lib/shelfmark";
      description = "Shelfmark state directory.";
    };
    secretFile = lib.mkOption {
      type = lib.types.path;
      description = "Age-encrypted environment file containing database credentials.";
    };
    openFirewall = lib.mkEnableOption "direct LAN access to Grimmory on TCP port 6060";
    tailscaleServe = lib.mkEnableOption "publishing Grimmory and Shelfmark as Tailscale Services";
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.users.users.${cfg.owner}.uid != null;
        message = "The library service owner must have an explicit UID for container ownership.";
      }
      {
        assertion = config.users.groups.${cfg.group}.gid != null;
        message = "The library service group must have an explicit GID for container ownership.";
      }
    ];
    services.tailscale.enable = lib.mkIf cfg.tailscaleServe true;
    networking.firewall = {
      allowedTCPPorts = lib.optional cfg.openFirewall 6060;
      interfaces.grimmory.allowedUDPPorts = [ 53 ];
    };
    age.secrets.grimmory-env = {
      file = cfg.secretFile;
      mode = "0400";
    };
    virtualisation.quadlet =
      let
        inherit (config.virtualisation.quadlet) containers networks;
        userUid = toString config.users.users.${cfg.owner}.uid;
        usersGid = toString config.users.groups.${cfg.group}.gid;
        secretFile = config.age.secrets.grimmory-env.path;
        commonEnvironment = {
          TZ = config.time.timeZone;
        };
      in
      {
        networks.grimmory.networkConfig = {
          interfaceName = "grimmory";
          # Adopt the network created by the old oci-containers helper on the
          # first switch; subsequent lifecycle management belongs to Quadlet.
          podmanArgs = [ "--ignore" ];
        };

        # Pinned release tags, registry-qualified so podman short-name
        # resolution can't misfire under systemd; bump deliberately.
        containers.grimmory = {
          unitConfig = {
            # MariaDB uses Notify=healthy below, so this orders Grimmory after
            # the database is accepting connections, not merely after it starts.
            Requires = [ containers.grimmory-mariadb.ref ];
            After = [ containers.grimmory-mariadb.ref ];
          };
          containerConfig = {
            image = "ghcr.io/grimmory-tools/grimmory:v3.2.4@sha256:dfa7afdfcf25d649fd664497a62385dd00cd9678c37546e182c172e41c8e80cb";
            environments = commonEnvironment // {
              USER_ID = userUid;
              GROUP_ID = usersGid;
              DATABASE_URL = "jdbc:mariadb://grimmory-mariadb:3306/grimmory";
              DATABASE_USERNAME = "grimmory";
            };
            environmentFiles = [ secretFile ]; # DATABASE_PASSWORD
            volumes = [
              "${cfg.grimmoryStatePath}/data:/app/data" # app state, cache, logs
              "${cfg.libraryPath}:/books" # one subdir per Grimmory library (calibre, ...), indexed in place
              "${cfg.ingestPath}:/bookdrop" # drop books here to auto-import
            ];
            publishPorts = [ "${if cfg.openFirewall then "" else "127.0.0.1:"}6060:6060" ];
            networks = [ networks.grimmory.ref ];
          };
        };

        # Shelfmark — book search/request frontend (calibrain's successor to
        # calibre-web-automated-book-downloader). Integration with Grimmory is
        # purely file-based: downloads land in the ingest dir (its /books,
        # Grimmory's /bookdrop) and Grimmory auto-imports them, so it needs
        # neither the grimmory network nor any credentials. All runtime
        # configuration (sources, users) lives in /config via the web UI.
        # Localhost-only: no LAN clients, tailnet access via tailscale serve.
        containers.shelfmark.containerConfig = {
          image = "ghcr.io/calibrain/shelfmark:v1.3.13@sha256:ee0f3a15a8cc37a43a39fb9e768eac0c9a4ac328014b9b914bad7c1be232bd90";
          environments = commonEnvironment // {
            PUID = userUid;
            PGID = usersGid;
          };
          volumes = [
            "${cfg.shelfmarkStatePath}:/config" # settings + request database
            "${cfg.ingestPath}:/books" # = Grimmory's /bookdrop
          ];
          publishPorts = [ "127.0.0.1:8084:8084" ];
        };

        containers.grimmory-mariadb.containerConfig = {
          # The linuxserver image (as in Grimmory's reference compose) for its
          # PUID/PGID handling, keeping the data directory owned by the configured account.
          image = "lscr.io/linuxserver/mariadb:11.4.5@sha256:eef506eab5c5e5aaa3ce6d1237dcfa5742a8dafd9054e668c838fad71b0d1547";
          environments = commonEnvironment // {
            PUID = userUid;
            PGID = usersGid;
            MYSQL_DATABASE = "grimmory";
            MYSQL_USER = "grimmory";
          };
          healthCmd = "mariadb-admin ping --host=127.0.0.1 --silent";
          healthInterval = "5s";
          healthRetries = 20;
          healthStartPeriod = "60s";
          healthTimeout = "3s";
          notify = "healthy";
          environmentFiles = [ secretFile ]; # MYSQL_{ROOT_,}PASSWORD
          volumes = [ "${cfg.grimmoryStatePath}/mariadb:/config" ];
          # No published ports: only reachable over the grimmory podman network.
          networks = [ networks.grimmory.ref ];
        };
      };

    # The containers chown these to the configured UID:GID at startup, but they
    # must exist before podman can bind-mount them.
    systemd.tmpfiles.rules = [
      "d ${cfg.grimmoryStatePath} 0750 root ${cfg.group} -"
      "d ${cfg.grimmoryStatePath}/data 0750 ${cfg.owner} ${cfg.group} -"
      "d ${cfg.grimmoryStatePath}/mariadb 0750 ${cfg.owner} ${cfg.group} -"
      "d ${cfg.shelfmarkStatePath} 0750 ${cfg.owner} ${cfg.group} -"
      "d ${cfg.ingestPath} 0755 ${cfg.owner} ${cfg.group} -"
    ];

    # Serve Grimmory as a Tailscale Service: it gets its own DNS name
    # (https://grimmory.<tailnet>.ts.net) and virtual IP, leaving the host's
    # hostname free for other services (one unit like this per service).
    # The tailnet-side half lives in the admin console: the svc:grimmory
    # definition, host approval, and an ACL grant for access (port 443).
    # `serve --service` only runs in the background, so model it as a oneshot
    # whose stop action clears the service config again.
    systemd.services.tailscale-serve-grimmory = lib.mkIf cfg.tailscaleServe {
      description = "Advertise Grimmory as Tailscale Service svc:grimmory";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      # tailscaled's local API may not be ready right at boot; wait for it.
      preStart = "until ${config.services.tailscale.package}/bin/tailscale status --peers=false >/dev/null 2>&1; do sleep 1; done";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:grimmory --yes --https=443 127.0.0.1:6060";
        # Clears the whole service config, i.e. the port mapping above.
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve clear svc:grimmory";
      };
    };

    systemd.services.tailscale-serve-shelfmark = lib.mkIf cfg.tailscaleServe {
      description = "Advertise Shelfmark as Tailscale Service svc:shelfmark";
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      preStart = "until ${config.services.tailscale.package}/bin/tailscale status --peers=false >/dev/null 2>&1; do sleep 1; done";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --service=svc:shelfmark --yes --https=443 127.0.0.1:8084";
        ExecStop = "${config.services.tailscale.package}/bin/tailscale serve clear svc:shelfmark";
      };
    };
  };
}
