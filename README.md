# eikopf/flake

Personal NixOS and macOS configurations using Home Manager, nix-darwin, and
nix-homebrew. The flake manages desktop environments, everyday tools, and homelab
services across these machines:

| Host | OS | Architecture | Roles |
|---|---|---|---|
| Pilatus | macOS | aarch64 | Personal laptop |
| Wildspitz | NixOS | x86_64 | Personal workstation (hosts some Tailscale services) |

## Structure

Hosts select reusable profiles and supply device-specific settings. Profiles
combine capabilities into roles, so one host can be both a workstation and a
homelab machine.

- `flake.nix`: inputs, personal identity, and host inventory.
- `lib/`: configuration constructors, checks, and development shell.
- `hosts/`: hardware, hostnames, profile selection, and service deployment settings.
- `profiles/`: shared personal, workstation, and homelab configurations.
- `modules/`: system capabilities, grouped into common, NixOS, and Darwin modules.
- `home/`: Home Manager programs, profiles, and desktop configuration.
- `secrets/` and `secrets.nix`: agenix-encrypted secrets and their recipient policy.
- `wallpaper/`: desktop assets.
- [AGENTS.md](AGENTS.md): development and maintenance instructions.

The library service module runs Grimmory, MariaDB, and Shelfmark. Its host selects
storage paths, ownership, credentials, and LAN or Tailscale publication.

The Darwin personal profile uses Lix. Neovim configuration is managed separately
in `~/.config/nvim`. Project development environments provide compilers, SDKs, and
language tooling independently of the host configuration.

## Secrets and fonts

Secrets are encrypted with agenix. Each host has a keyset containing its user and
host keys plus the backup keys; the combined `all` keyset is the default recipient
set.

Berkeley Mono is stored encrypted in `secrets/fonts/`. The shared desktop profile
decrypts it at login into the user's font directory on Linux and macOS. Plaintext
fonts stay outside the Nix store.
