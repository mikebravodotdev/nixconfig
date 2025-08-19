{
  description = "my primary flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Optional: Declarative tap management
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
      specialArgs = { inherit self; };
      # CORRECTED: The modules list is now a clean list of files/imports
      modules = [
        nix-homebrew.darwinModules.nix-homebrew # The module itself
        ./configuration.nix
        ./packages.nix
        ./applications.nix
        ./homebrew.nix  # Your new homebrew configuration file
      ];
    };
  };
}
