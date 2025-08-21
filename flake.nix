{
  description = "my primary flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask }:
  {
    darwinConfigurations."Hermes" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit (inputs) self homebrew-core homebrew-cask; };

      modules = [
        nix-homebrew.darwinModules.nix-homebrew # The module itself
        ./configuration.nix
        ./packages.nix
        ./applications.nix
        ./NSGlobalDomain.nix # Global configurations
        ./trackpad.nix # My custom trackpad settings
        ./homebrew.nix  # Your new homebrew configuration file
      ];
    };
  };
}
