# Default: list available recipes
default:
    just --list

# Rebuild and activate the current host
switch:
    #!/usr/bin/env sh
    if [ "$(uname)" = "Darwin" ]; then
        darwin-rebuild switch --flake .
    else
        sudo nixos-rebuild switch --flake .
    fi

# Evaluate every host configuration; builds nothing
check:
    nix flake check --no-build

# Format all Nix files
fmt:
    nix fmt

# Update all flake inputs
update:
    nix flake update
