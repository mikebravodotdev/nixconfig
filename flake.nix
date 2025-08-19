{
  description = "my primary flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
    {
      darwinConfigurations."Hermes" = nix-darwin.lib.darwinSystem {
        # The system's architecture
        system = "aarch64-darwin";

        # Special arguments passed to your modules
        specialArgs = { inherit self; };

        # List of modules to import.
        # Nix will automatically merge the settings from all these files.
        modules = [
          ./configuration.nix
          ./packages.nix
          ./applications.nix
        ];
      };
    };
  }
