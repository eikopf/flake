# Evaluate role boundaries without any existing host or hardware configuration.
{
  inputs,
  system,
  identity,
}:
let
  inherit (inputs.nixpkgs) lib;
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  evaluate =
    modules:
    (lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs identity;
        user = identity.username;
      };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        ../modules/common
        ../modules/nixos
        {
          system.stateVersion = "26.05";
          # Synthetic hardware permits forcing system assertions for fixtures.
          boot.loader.grub.enable = false;
          fileSystems."/" = {
            device = "none";
            fsType = "tmpfs";
          };
        }
      ]
      ++ modules;
    }).config;
  server = evaluate [ ../profiles/nixos/homelab.nix ];
  workstation = evaluate [
    ../profiles/nixos/workstation.nix
    ../modules/nixos/desktops/sway.nix
    { home-manager.users.${identity.username}.home.stateVersion = "26.05"; }
  ];
  disabledLibrary = evaluate [ ../modules/nixos/services/library.nix ];
  library = evaluate [
    ../profiles/nixos/homelab.nix
    ../modules/nixos/services/library.nix
    {
      users.users.library = {
        isSystemUser = true;
        uid = 987;
        group = "library";
      };
      users.groups.library.gid = 987;
      personal.services.library = {
        enable = true;
        owner = "library";
        group = "library";
        libraryPath = "/srv/books";
        ingestPath = "/srv/bookdrop";
        grimmoryStatePath = "/srv/grimmory";
        shelfmarkStatePath = "/srv/shelfmark";
        secretFile = ../secrets/grimmory.env.age;
      };
    }
  ];
  grimmory = library.virtualisation.quadlet.containers.grimmory.containerConfig;
  expect = message: condition: if condition then true else throw message;
  checks = [
    (expect "Homelab must not enable desktop services" (
      !server.services.pipewire.enable
      && !server.services.printing.enable
      && !server.services.xserver.enable
      && !server.programs.sway.enable
      && !server.networking.networkmanager.enable
    ))
    (expect "Homelab must not create a personal account or home" (
      !(server.users.users ? ${identity.username}) && server.home-manager.users == { }
    ))
    (expect "Homelab must not choose UEFI or advertise an exit node" (
      !server.boot.loader.systemd-boot.enable
      && !(lib.elem "--advertise-exit-node" server.services.tailscale.extraSetFlags)
    ))
    (expect "Workstation must provide Sway and the shared Firefox configuration" (
      workstation.programs.sway.enable
      && workstation.home-manager.users.${identity.username}.programs.firefox.enable
      && workstation.home-manager.users.${identity.username}.programs.firefox.policies.DisableTelemetry
    ))
    (expect "Workstation must not enable homelab administration or library ports" (
      !workstation.services.openssh.enable
      && !workstation.services.tailscale.enable
      && !(lib.elem 6060 workstation.networking.firewall.allowedTCPPorts)
    ))
    (expect "A disabled library must need no deployment options or services" (
      disabledLibrary.virtualisation.quadlet.containers == { }
      && disabledLibrary.age.secrets == { }
      && !(lib.elem 6060 disabledLibrary.networking.firewall.allowedTCPPorts)
    ))
    (expect "Library relocation must use the assigned service account" (
      grimmory.environments.USER_ID == "987"
      && grimmory.environments.GROUP_ID == "987"
      && !(library.users.users ? ${identity.username})
    ))
    (expect "Library relocation must use the assigned storage" (
      grimmory.volumes == [
        "/srv/grimmory/data:/app/data"
        "/srv/books:/books"
        "/srv/bookdrop:/bookdrop"
      ]
      &&
        library.virtualisation.quadlet.containers.shelfmark.containerConfig.volumes == [
          "/srv/shelfmark:/config"
          "/srv/bookdrop:/books"
        ]
    ))
    (expect "Library publication must be opt-in" (
      grimmory.publishPorts == [ "127.0.0.1:6060:6060" ]
      && !(lib.elem 6060 library.networking.firewall.allowedTCPPorts)
      && !(library.systemd.services ? tailscale-serve-grimmory)
    ))
    # Force module assertions as well as the selected boundary checks.
    (expect "Workstation fixture assertions must pass" (
      lib.all (a: a.assertion) workstation.assertions
    ))
    (expect "Library fixture assertions must pass" (lib.all (a: a.assertion) library.assertions))
  ];
in
assert lib.all (value: value) checks;
pkgs.runCommand "profile-composition-check" { } ''
  touch $out
''
