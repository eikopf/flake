# eikopf/flake

Personal NixOS and macOS configurations using Home Manager, nix-darwin, and
nix-homebrew. The flake manages desktop environments, everyday tools, and homelab
services across these machines:

| Host | System | Roles |
|---|---|---|
| Pilatus | Apple Silicon macOS | Personal workstation with AeroSpace |
| Wildspitz | x86_64 NixOS | Workstation with Sway, homelab, Tailscale exit node |

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

The library service module runs Grimmory, MariaDB, and Shelfmark. Its host selects
storage paths, ownership, credentials, and LAN or Tailscale publication. Project
compilers, SDKs, and language tooling belong in each project's development environment.

## Usage

Run commands from the checkout. `nix develop` provides the maintenance tools;
`direnv allow` enables automatic activation through the repository's `.envrc`.

| Command | Action |
|---|---|
| `just check` | Evaluate every host across platforms without building |
| `just lint` | Run formatting and dead-code checks |
| `just build <host>` | Build a host for the local OS without activating it |
| `just switch` | Rebuild and activate the current host |
| `just fmt` | Format Nix files |
| `just update` | Update flake inputs |

Activation requires NixOS or an existing nix-darwin installation. The Darwin
personal profile uses Lix. Neovim configuration is managed separately in
`~/.config/nvim`.

## Adding a host

Create `hosts/<name>/default.nix` and register its `system` and `platform` in
`flake.nix`. Import the appropriate profiles and modules, then set the hostname,
hardware configuration, and system and Home Manager `stateVersion` values.
Preserve these compatibility versions during subsequent upgrades.

Stage new files with Git, run `just check` and `just lint`, then build on the target
platform before activating. For service secrets, add the host's public key to
`secrets.nix` and rekey with `agenix -r` using an authorized identity.

## Private fonts

Berkeley Mono is stored encrypted in `secrets/fonts/`. The shared desktop profile
uses agenix to decrypt it at login into the user font directory on Linux and macOS;
plaintext fonts stay outside the Nix store. Decryption requires a user SSH private
key listed in `secrets.nix` (agenix checks `~/.ssh/id_ed25519` and `~/.ssh/id_rsa`).

Each host has a keyset containing its user and host keys plus the backup keys.
Secrets use the combined `all` keyset by default. After adding keys in `secrets.nix`,
run `nix develop` and `agenix -r` from the repository root to re-encrypt the secrets.
User font installation requires a private key readable by that user.
