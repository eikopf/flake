{
  description = "Personal machines and infrastructure — eikopf/flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

    darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "darwin";
      inputs.home-manager.follows = "home-manager";
    };

    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      darwin,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      identity = {
        username = "oliver";
        fullName = "Oliver Wooding";
        email = "oliver@wooding.dev";
      };
      hosts = {
        rigi = {
          system = "x86_64-linux";
          platform = "nixos";
        };
        wildspitz = {
          system = "x86_64-linux";
          platform = "nixos";
        };
        pilatus = {
          system = "aarch64-darwin";
          platform = "darwin";
        };
      };
      forAllSystems = lib.genAttrs (lib.unique (map (host: host.system) (lib.attrValues hosts)));
      hostsFor = platform: lib.filterAttrs (_: host: host.platform == platform) hosts;
      mkHost =
        name: host:
        let
          isDarwin = host.platform == "darwin";
          constructor = if isDarwin then darwin.lib.darwinSystem else lib.nixosSystem;
        in
        constructor {
          system = host.system;
          specialArgs = {
            inherit self inputs identity;
            user = identity.username;
          };
          modules = [
            ./hosts/${name}
            ./modules/common
            (if isDarwin then ./modules/darwin else ./modules/nixos)
            (
              if isDarwin then home-manager.darwinModules.home-manager else home-manager.nixosModules.home-manager
            )
          ];
        };
      repositoryChecks =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
            deadnix --fail ${self}
            touch $out
          '';
          formatting = pkgs.runCommand "formatting-check" { nativeBuildInputs = [ pkgs.nixfmt-tree ]; } ''
            treefmt --ci ${self}
            touch $out
          '';
        };
    in
    {
      nixosConfigurations = lib.mapAttrs mkHost (hostsFor "nixos");
      darwinConfigurations = lib.mapAttrs mkHost (hostsFor "darwin");
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      # --all-systems --no-build evaluates every host, including Darwin on Linux.
      # Building these checks builds the corresponding complete host closures.
      checks = forAllSystems (
        system:
        repositoryChecks system
        // lib.mapAttrs (
          name: host:
          if host.platform == "darwin" then
            self.darwinConfigurations.${name}.system
          else
            self.nixosConfigurations.${name}.config.system.build.toplevel
        ) (lib.filterAttrs (_: host: host.system == system) hosts)
      );
      # This repository is itself a project: maintenance tools belong in its shell.
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              just
              nixfmt-tree
              deadnix
            ];
          };
        }
      );
    };
}
