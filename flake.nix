{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget

      # macOS defaults
        system.defaults = {
          dock.autohide = true;
          dock.mru-spaces = false;
          #finder.AppleShowAllExtensions = true;
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.LoginwindowText = "The way is shut. It was made by those who are dead, and the Dead keep it, until the time comes. The way is shut.";
          screencapture.location = "/Users/mikebravo/Library/Mobile\ Documents/com~apple~CloudDocs/Screenshots";
          screensaver.askForPasswordDelay = 10;
        };

      security.pam.services.sudo_local.touchIdAuth = true;
      environment.systemPackages =
        [ pkgs.vim
        ];

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      # Set the primary user for user-specific settings.
      system.primaryUser = "mikebravo";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."Hermes" = nix-darwin.lib.darwinSystem {
      modules = [ configuration ];
    };
  };
}
