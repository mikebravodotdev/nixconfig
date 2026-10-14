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
    cliamp.url = "github:bjarneo/cliamp";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask, home-manager, nixvim, cliamp }:
  let
    username = "mikebravo";

    # Passed to every home-manager module, on both platforms.
    homeSpecialArgs = { inherit nixvim cliamp username; };

    # macOS: nix-darwin owns the system layer (defaults, Homebrew, Touch ID)
    # and runs home-manager as a module for everything user-level.
    # Same config for every Mac right now — add per-host modules to a
    # given entry below if/when a machine needs to diverge (e.g. a
    # trimmed Homebrew cask list).
    mkDarwinSystem = { system ? "aarch64-darwin" }: nix-darwin.lib.darwinSystem {
      specialArgs = { inherit (inputs) self homebrew-core homebrew-cask; inherit username; };

      modules = [
        nix-homebrew.darwinModules.nix-homebrew # The module itself
        { nixpkgs.hostPlatform = system; }
        ./darwin/configuration.nix
        # ./darwin/NSGlobalDomain.nix # Global configurations
        # ./darwin/trackpad.nix # My custom trackpad settings
        ./darwin/homebrew.nix

        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Move aside any pre-existing ~/.bashrc etc. instead of refusing to activate.
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = homeSpecialArgs;
          home-manager.users.${username} = import ./home;
        }
      ];
    };

    # Linux (non-NixOS, e.g. Fedora): standalone home-manager, no system layer.
    mkHome = { system ? "x86_64-linux" }: home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      extraSpecialArgs = homeSpecialArgs;
      modules = [ ./home ];
    };
  in
  {
    darwinConfigurations = {
      "Hermes" = mkDarwinSystem { };
      "myMacmini" = mkDarwinSystem { };
    };

    # `home-manager switch --flake .` picks "<user>@<hostname>" automatically.
    homeConfigurations = {
      "${username}@ares" = mkHome { };
    };
  };
}
