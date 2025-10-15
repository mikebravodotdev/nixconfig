# configuration.nix

{ self, pkgs,... }:

{
# Allow installation of unfree packages
  nixpkgs.config.allowUnfree = true;

# macOS defaults
  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    #finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "clmv";
    loginwindow.LoginwindowText = "The way is shut. It was made by those who are dead, and the Dead keep it, until the time comes. The way is shut.";
    screencapture.location = "/Users/mikebravo/Library/Mobile\ Documents/com~apple~CloudDocs/Screenshots";
    screensaver.askForPasswordDelay = 10;
    #trackpad.TrackpadThreeFingerDrag = true;
    #NSGlobalDomain."com.apple.trackpad.scaling" = 3;
  };

# Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

# Add community caches to avoid building from source
nix.settings = {
  substituters = [ "https://cache.nixos.org/" "https://nix-community.cachix.org/" ];
  trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" "nix-community.cachix.org-1:mB9FSh9UfP3dIR2A7ahVdvr30QKGXobOYA7RMCCEgLg=" ];
};

# Flakes settings
  nix.settings.experimental-features = "nix-command flakes";

# Enable programs and set default shell
  programs.bash.enable = true;
  users.users.mikebravo.shell = pkgs.bash;

# System settings
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "mikebravo";
}
