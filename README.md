# eikopf/flake

Personal NixOS and macOS machines, home environments, and homelab deployments.
Upstream: [eikopf/flake](https://github.com/eikopf/flake).

## Configuration model

Hosts compose machine profiles and assign hardware and deployment details.
Profiles assemble reusable capabilities. Modules configure individual capabilities.
A machine can have multiple roles: Wildspitz is both a workstation and a homelab host.

| Host | Profiles | Host-specific choices |
|---|---|---|
| Pilatus | Darwin personal | Hostname, compatibility versions |
| Rigi | NixOS workstation | Plasma, NVIDIA hardware, disks, keyboard layout |
| Wildspitz | NixOS workstation + homelab | Sway, AMD hardware, monitor, security token, library deployment, exit node |

```text
flake.nix                    Inputs, host inventory, constructors, checks, dev shell
hosts/<name>/                Profile selection, hardware, deployment assignments
profiles/common/personal.nix Personal account and Home Manager integration
profiles/darwin/personal.nix  Normal Mac applications, preferences, services
profiles/nixos/workstation.nix Desktop facilities and personal applications
profiles/nixos/homelab.nix    Remote administration and host networking policy
modules/common/              Minimal shared Nix and system shell configuration
modules/darwin/              Individual macOS capabilities
modules/nixos/               Individual NixOS capabilities, desktops, services
home/programs/               Home Manager application configuration
home/profiles/               Personal CLI, desktop apps, development conveniences
home/desktops/               Reusable desktop sessions and appearance
secrets/                     Encrypted deployment secrets
secrets.nix                  Encryption recipient policy
wallpaper/                   Desktop assets
```

The constructors install only platform foundations and the Home Manager module
framework. Personal accounts, GUI applications, desktop services, Homebrew, and
homelab workloads are selected by profiles or hosts. Profiles and reusable modules
must not import a host directory or name a particular device.

The homelab profile does not create a personal account, install a desktop, select a
bootloader, advertise an exit node, or enable library services. Select these
separately where needed. The Tailscale module enables Tailscale SSH; its exit-node
module is a separate opt-in. Wildspitz's trusted-tailnet firewall policy remains an
explicit host choice.

## Adding a machine

1. Add `hosts/<name>/default.nix` and register its `system` and `platform` (`nixos`
   or `darwin`) in the `hosts` inventory in `flake.nix`. Checks and formatter/shell
   architectures are derived from that inventory.
2. Import suitable profiles and capabilities. NixOS hosts also supply their disks,
   bootloader, and other hardware details. `modules/nixos/uefi.nix` is available for
   systemd-boot machines; it is not a platform-wide assumption.
3. Set the hostname and installation compatibility versions. Personal profiles
   require `home-manager.users.oliver.home.stateVersion`; NixOS and Darwin require
   `system.stateVersion`. Preserve existing values during upgrades and refactors.
4. Set device exceptions, such as a different account UID, monitor layout, or
   authentication token. Linux personal accounts default to UID 1000; macOS to 501.
5. Stage new files so Git-backed flake evaluation includes them, then run `just check`
   and `just lint`. Build on the target platform before activating.

For example, another regular Mac imports `profiles/darwin/personal.nix`; it need
not copy Pilatus's application list. A headless NixOS machine imports
`profiles/nixos/homelab.nix` and defines its own administrative accounts and hardware.
Add `profiles/common/personal.nix` only if the personal CLI environment is wanted.

To bootstrap a Mac, install Lix, clone this repository, and run the pinned Darwin
input's rebuild tool from the checkout:

```sh
git clone git@github.com:eikopf/flake.git ~/.config/nix
cd ~/.config/nix
darwin_rebuild=$(nix build --no-link --print-out-paths --expr \
  'let f = builtins.getFlake (toString ./.); in f.inputs.darwin.packages.aarch64-darwin.darwin-rebuild' \
  --impure)
sudo "$darwin_rebuild/bin/darwin-rebuild" switch --flake .#pilatus
```

Replace `pilatus` with the registered host name when bootstrapping another Mac.
After bootstrapping, use `just switch`. The Darwin personal profile manages Lix
explicitly. The checkout path can differ; recipes operate on the current checkout.

## Moving the library workload

`modules/nixos/services/library.nix` owns Grimmory, MariaDB, Shelfmark, their
container network, directory creation, credentials, and optional publication.
Import it and enable `personal.services.library` on the receiving host:

```nix
personal.services.library = {
  enable = true;
  owner = "library";
  group = "library";
  libraryPath = "/srv/books";
  ingestPath = "/srv/bookdrop";
  secretFile = ../../secrets/grimmory.env.age;
  openFirewall = false;
  tailscaleServe = true;
};
```

Create the named account and group with explicit numeric UID/GID values. The module
does not assume that the service owner is a desktop user. State directories default
to `/var/lib/grimmory` and `/var/lib/shelfmark`; override `grimmoryStatePath` and
`shelfmarkStatePath` if needed. The existing library must already exist; the ingest
and application state directories are created by tmpfiles.

Both publication options default to false: Grimmory then binds to localhost and
Shelfmark always binds to localhost. `openFirewall` exposes Grimmory on TCP 6060 for
LAN clients such as KOReader. `tailscaleServe` publishes the fixed service names
`svc:grimmory` and `svc:shelfmark`; definitions, approvals, and access grants live in
the Tailscale admin console.

Moving the declarations does not move data. Stop the old workload, migrate the book
library and all application/database state with appropriate ownership, authorize
the new host to decrypt the secret, and transfer Tailscale service approval before
activating the replacement. Wildspitz currently retains its existing paths, owner,
image digests, and exposure settings.

## Development environments

There is no global `languages` module. Projects own compiler versions, language
servers, formatters, SDKs, build tools, and dependency environments in their own
flakes or other project configuration. The host does not install the former
Haskell/OCaml/Java/JavaScript/etc. toolchains or Pilatus's ESP tools, QEMU, and pnpm.
Rustup, elan, uv, and language-specific document tooling are also removed from the
host environment; add them to the projects that use them.

The personal development profile keeps `nixd`, `nixfmt`, and `devenv`. Home Manager
provides direnv with nix-direnv integration. Project `.envrc` files can use
`use flake`; launch editors from the activated environment so their language
servers inherit project tools. Neovim's configuration remains separately managed
in `~/.config/nvim`.

This repository has its own development shell with `just`, `nixfmt-tree`, and
`deadnix`. Enter with `nix develop`, or run `direnv allow` after reviewing `.envrc`.
Kitty and Neovide have been removed; Ghostty is the shared desktop terminal.
Linux workstations share Firefox policies, Anki, and VS Code (without the
project-specific Lean extension). macOS retains Homebrew Ghostty and coding agents,
Docker/OrbStack, MonitorControl, and hledger.

## Commands and validation

| Recipe | Action |
|---|---|
| `just check` | Evaluate all hosts and checks across architectures; build nothing |
| `just lint` | Run local lint and Linux role-composition checks |
| `just build <host>` | Build a host for the local OS without activation |
| `just switch` | Rebuild and activate the current host |
| `just fmt` | Format Nix files |
| `just update` | Update all flake inputs |

`nix flake check --all-systems --no-build --no-update-lock-file` includes Darwin
checks when run on Linux. Without `--all-systems`, foreign-system checks are
omitted. Evaluation does not execute linters or prove that systems build or boot.
Plain `nix flake check` also builds local-platform host closures because they are
registered as checks. Linux role-composition checks also evaluate a headless homelab,
a workstation, and a relocated library with a separate service account.
Use an appropriate platform or remote builder for full builds.
Rigi has not been boot-tested recently.

## Secrets and external state

Encrypted `.age` files and recipient policy belong in this infrastructure flake.
With agenix available (installed on Wildspitz):

```sh
agenix -e secrets/grimmory.env.age
git add secrets/grimmory.env.age
just check
```

When moving services, update `secrets.nix` with the new host's public key and rekey
with `agenix -r` before deployment. Never commit decrypted credentials.

Homebrew applications, browser-downloaded extensions, Tailscale enrollment/policy,
service databases, and the external Neovim configuration have their own state or
update lifecycle. Berkeley Mono is a commercial font installed separately; the
Linux workstation profile supplies Noto fallback fonts.
