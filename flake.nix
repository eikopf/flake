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
    inputs:
    import ./lib/mk-flake.nix {
      inherit inputs;
      identity = {
        username = "oliver";
        fullName = "Oliver Wooding";
        email = "oliver@wooding.dev";
      };
      hosts = {
        wildspitz = {
          system = "x86_64-linux";
          platform = "nixos";
        };
        pilatus = {
          system = "aarch64-darwin";
          platform = "darwin";
        };
      };
    };
}
