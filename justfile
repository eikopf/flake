# Default: list available recipes
default:
    just --list

# Evaluate every host, including the other OS; build nothing
check:
    nix flake check --all-systems --no-build --no-update-lock-file

# Run repository checks without building complete host systems
lint:
    #!/usr/bin/env sh
    set -eu
    system=$(nix eval --impure --raw --expr builtins.currentSystem)
    nix build --no-link --no-update-lock-file ".#checks.$system.deadnix" ".#checks.$system.formatting"

# Build one host without activating it
build host:
    #!/usr/bin/env sh
    set -eu
    if [ "$(uname)" = "Darwin" ]; then
        nix build --no-link '.#darwinConfigurations.{{host}}.system'
    else
        nix build --no-link '.#nixosConfigurations.{{host}}.config.system.build.toplevel'
    fi

# Rebuild and activate the current host
switch:
    #!/usr/bin/env sh
    set -eu
    if [ "$(uname)" = "Darwin" ]; then
        sudo darwin-rebuild switch --flake .
    else
        sudo nixos-rebuild switch --flake .
    fi

# Format all Nix files
fmt:
    nix fmt

# Update all flake inputs
update:
    nix flake update
