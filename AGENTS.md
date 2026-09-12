# Working in this repository

Keep README.md a brief description of the current flake. Only agent-specific
guidance belongs in AGENTS.md.

## Configuration changes

- Keep `flake.nix` focused on inputs, identity, and the host inventory. Put helper
  definitions in `lib/`.
- Hosts select profiles and supply hardware and deployment settings. Profiles
  combine reusable modules into machine roles; workstation and homelab roles
  must remain independently usable.
- Put personal application configuration in Home Manager. Keep project-specific
  compilers, SDKs, language servers, and build tools in their project environments.
- Preserve system and Home Manager `stateVersion` values during upgrades.

## Commands and validation

Run commands from the checkout. `nix develop` provides maintenance tools;
`direnv allow` enables automatic activation through `.envrc`.

| Command | Action |
|---|---|
| `just check` | Evaluate every host across platforms without building |
| `just lint` | Run formatting and dead-code checks |
| `just build <host>` | Build a host for the local OS without activating it |
| `just switch` | Rebuild and activate the current host |
| `just fmt` | Format Nix files |
| `just update` | Update flake inputs |

For Nix changes, format the edited files, stage new files so Git-backed flake
imports can see them, and run `just check` and `just lint`. Build an affected host
on its target platform when validating package or system changes. Evaluation and
builds do not verify activation or boot behavior. Documentation-only changes need
review and `git diff --check`, not host builds.

`just check` uses `--all-systems --no-build` to include Darwin when run on Linux.
Plain `nix flake check` also builds local-platform host closures. Activation requires
NixOS or an existing nix-darwin installation; the Darwin personal profile uses Lix.

## Adding a host

Create `hosts/<name>/default.nix` and register its `system` and `platform` (`nixos`
or `darwin`) in `flake.nix`. Import suitable profiles and modules, then set the
hostname, hardware configuration, and initial system and Home Manager `stateVersion`
values. Checks and supported architectures are derived from the host inventory.

## Keys and encrypted files

Name host-specific key variables `<hostname>-<context>`, such as `pilatus-oliver`
and `pilatus-host`. Backup key names are independent of this convention. Add host
keys to `hostKeys` in `secrets.nix`; per-host keysets include backups automatically.
Use `keysets.all` for secrets unless there is a concrete reason to restrict access.

After changing recipients, run `agenix -r` from the repository root inside
`nix develop`, using an authorized private identity. Commit the updated ciphertext
alongside the recipient policy. Keep decrypted secrets and fonts out of Git and
the Nix store.

Font installation runs as the user. Agenix checks `~/.ssh/id_ed25519` and
`~/.ssh/id_rsa` by default, so each desktop user needs a readable private key whose
public key is included in the recipients. A host key alone does not provide access
to the user service. The shared font module lives in `home/fonts/berkeley-mono.nix`.
