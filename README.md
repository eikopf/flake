# eikopf/flake

Personal NixOS and macOS configurations. This flake manages the following machines:

| Host | OS | Architecture | Roles |
|---|---|---|---|
| Pilatus | macOS | aarch64 | Personal laptop |
| Wildspitz | NixOS | x86_64 | Personal workstation (hosts some Tailscale services) |

## Structure

Each host uses the base configuration for its OS (`modules/darwin` or `modules/nixos`),
selects zero or more role-specific profiles (under `profiles/`), and provides some
one-off configurations (under `hosts/<hostname>`). Profiles represent the "purpose"
of a host, so e.g. a NixOS workstation would use `profiles/nixos/workstation`.

- `flake.nix`: inputs, personal identity, and host inventory.
- `lib/`: configuration constructors, checks, and development shell.
- `hosts/`: hardware, hostnames, profile selection, and service deployment settings.
- `profiles/`: shared personal, workstation, and homelab configurations.
- `modules/`: system capabilities, grouped into common, NixOS, and Darwin modules.
- `home/`: Home Manager programs, profiles, and desktop configuration.
- `secrets/` and `secrets.nix`: agenix-encrypted secrets and their recipient policy.
- `wallpaper/`: desktop assets.

## Secrets and fonts

Secrets are encrypted with agenix. Each host has a keyset containing its user and
host keys plus the backup keys; the combined `all` keyset is the default recipient
set.

Berkeley Mono is stored encrypted in `secrets/fonts/`. The shared desktop profile
decrypts it at login into the user's font directory on Linux and macOS. Plaintext
fonts stay outside the Nix store.
