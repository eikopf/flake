{
  description = "Core Nix configuration flake";

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
      nix-homebrew,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs supportedSystems;

      identity = {
        username = "oliver";
        fullName = "Oliver Wooding";
        email = "oliver@wooding.dev";
        linuxUid = 1000;
        darwinUid = 501;
      };

      mkHomeManagerModule = identity: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.extraSpecialArgs = { inherit identity; };
        home-manager.users.${identity.username} = import ./home;
      };

      mkNixosHost =
        {
          identity,
          name,
          system,
          extraModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit identity inputs;
            user = identity.username;
          };

          modules = [
            ./hosts/${name}
            ./modules/common
            ./modules/nixos
            ./modules/languages
            inputs.agenix.nixosModules.default
            inputs.quadlet-nix.nixosModules.quadlet
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule identity)
          ]
          ++ extraModules;
        };

      mkDarwinHost =
        {
          identity,
          name,
          system,
          extraModules ? [ ],
        }:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit self identity inputs;
            user = identity.username;
          };

          modules = [
            ./hosts/${name}
            ./modules/common
            ./modules/darwin
            ./modules/languages
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            (mkHomeManagerModule identity)
          ]
          ++ extraModules;
        };
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      # checks exist so `nix flake check` evaluates every host config; cross-host
      # regressions surface immediately even though only the current system's
      # checks get built locally.
      checks = {
        x86_64-linux = {
          rigi = self.nixosConfigurations.rigi.config.system.build.toplevel;
          wildspitz = self.nixosConfigurations.wildspitz.config.system.build.toplevel;
        };
        aarch64-darwin = {
          pilatus = self.darwinConfigurations.pilatus.system;
        };
      };

      nixosConfigurations = {
        rigi = mkNixosHost {
          inherit identity;
          name = "rigi";
          system = "x86_64-linux";
        };

        wildspitz = mkNixosHost {
          inherit identity;
          name = "wildspitz";
          system = "x86_64-linux";
        };
      };

      darwinConfigurations = {
        pilatus = mkDarwinHost {
          inherit identity;
          name = "pilatus";
          system = "aarch64-darwin";
        };
      };
    };
}
