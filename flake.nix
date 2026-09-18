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
    # Deliberately not following our nixpkgs pin here: home-manager/master's
    # module system has needed nixpkgs internals (e.g. lib/services) that
    # our nixpkgs-unstable pin doesn't have yet. Let it use its own tested pin.
    home-manager.url = "github:nix-community/home-manager/master";
    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask, home-manager, nixvim }:
  let
    # Same config for every machine right now — add per-host modules to a
    # given entry below if/when a machine needs to diverge (e.g. a
    # different architecture or a trimmed Homebrew cask list).
    mkDarwinSystem = { system ? "aarch64-darwin" }: nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit (inputs) self homebrew-core homebrew-cask; };

      modules = [
        nix-homebrew.darwinModules.nix-homebrew # The module itself
        ./configuration.nix
        ./packages.nix
        # ./applications.nix
        # ./NSGlobalDomain.nix # Global configurations
        # ./trackpad.nix # My custom trackpad settings
        ./homebrew.nix  # Your new homebrew configuration file

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit nixvim; };
          home-manager.users.mikebravo = import ./home.nix;
        }
      ];
    };
  in
  {
    darwinConfigurations = {
      "Hermes" = mkDarwinSystem { };
      "Familys-Mini" = mkDarwinSystem { };
    };
  };
}
