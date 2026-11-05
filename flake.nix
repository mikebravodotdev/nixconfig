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
    # Declarative Flatpak installs, for Linux GUI apps with no nixpkgs
    # package and no squashfs AppImage (e.g. ProtonPlus, which only ships a
    # DwarFS-packed AppImage that nixpkgs' appimageTools can't extract).
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    # Omarchy's theme palettes and wallpapers (MIT), used by the Linux desktop's
    # theme switcher (home/desktop.nix). Not a flake; pinned to the commit the
    # themes were taken from so they don't shift under us. Only the Linux
    # desktop module reads it, so evaluating the macOS configurations never
    # fetches it (locking does, once).
    omarchy = {
      url = "github:omacom/omarchy/a69b19f64efa78143155f2f46c85e7e05a09e05f";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask, home-manager, nixvim, cliamp, nix-flatpak, omarchy }:
  let
    username = "mikebravo";

    # Passed to every home-manager module, on both platforms.
    homeSpecialArgs = { inherit nixvim cliamp username omarchy; };

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
          # home/linux.nix sets services.flatpak, so the option must exist here too.
          home-manager.sharedModules = [ nix-flatpak.homeManagerModules.nix-flatpak ];
          home-manager.users.${username} = import ./home;
        }
      ];
    };

    # Linux on a non-NixOS distro (Debian 13 on bigGuy today): standalone
    # home-manager, no system layer. The Hyprland desktop's packages come from
    # apt. On NixOS use nixosConfigurations.bigGuy below instead. See
    # docs/linux-desktop.md.
    mkHome = { system ? "x86_64-linux" }: home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      extraSpecialArgs = homeSpecialArgs;
      modules = [ nix-flatpak.homeManagerModules.nix-flatpak ./home ];
    };
    # NixOS: the full-system counterpart to mkHome. Hardware lives in
    # hosts/<hostname>/ (hardware-configuration.nix + default.nix); home-manager
    # runs as a module and reuses ./home unchanged.
    mkNixos = { hostname, system ? "x86_64-linux" }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit username; };
      modules = [
        { nixpkgs.config.allowUnfree = true; }
        ./hosts/${hostname}
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = homeSpecialArgs;
          home-manager.sharedModules = [ nix-flatpak.homeManagerModules.nix-flatpak ];
          home-manager.users.${username} = {
            imports = [ ./home ];
            # NixOS provides this layer; the Debian shim must be off.
            targets.genericLinux.enable = nixpkgs.lib.mkForce false;
          };
        }
      ];
    };
  in
  {
    darwinConfigurations = {
      "Hermes" = mkDarwinSystem { };
      "myMacmini" = mkDarwinSystem { };
    };

    # `home-manager switch --flake .` picks "<user>@<hostname>" automatically.
    homeConfigurations = {
      "${username}@bigGuy" = mkHome { };
    };

    nixosConfigurations.bigGuy = mkNixos { hostname = "bigGuy"; };
  };
}
