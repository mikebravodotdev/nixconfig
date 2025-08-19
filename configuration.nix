# configuration.nix

{ self, ... }:

{
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

  # Enable Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  # Flakes settings
  nix.settings.experimental-features = "nix-command flakes";

  # System settings
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "mikebravo";
}
