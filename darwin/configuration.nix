# darwin/configuration.nix
# macOS system layer (nix-darwin). Everything user-level and cross-platform
# — packages, shell, editor, dotfiles — lives in ../home instead.

{ self, pkgs, username, hostname, ... }:

{
# Allow installation of unfree packages
  nixpkgs.config.allowUnfree = true;

# macOS defaults
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.3;
      mru-spaces = false;
      show-recents = false;
      tilesize = 48;
      orientation = "bottom";
      minimize-to-application = true;
    };
    #finder.AppleShowAllExtensions = true;
    finder = {
      FXPreferredViewStyle = "Nlsv"; # list view: the only view with columns
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    # "Use as Defaults" list-view options (columns, Calculate All Sizes). Only
    # folders without their own .DS_Store view settings pick these up.
    CustomUserPreferences."com.apple.finder".FK_StandardViewSettings.ListViewSettings = {
      calculateAllSizes = true;
      sortColumn = "name";
      iconSize = 16;
      textSize = 12;
      showIconPreview = true;
      useRelativeDates = true;
      viewOptionsVersion = 1;
      columns = {
        name         = { identifier = "name";         ascending = true;  index = 0; visible = true; width = 300; };
        dateModified = { identifier = "dateModified"; ascending = false; index = 1; visible = true; width = 181; };
        dateCreated  = { identifier = "dateCreated";  ascending = false; index = 2; visible = true; width = 181; };
        dateLastOpened = { identifier = "dateLastOpened"; ascending = false; index = 3; visible = true; width = 181; };
        dateAdded    = { identifier = "dateAdded";    ascending = false; index = 4; visible = true; width = 181; };
        size         = { identifier = "size";         ascending = false; index = 5; visible = true; width = 97; };
        kind         = { identifier = "kind";         ascending = true;  index = 6; visible = true; width = 115; };
        label        = { identifier = "label";        ascending = true;  index = 7; visible = false; width = 100; };
        version      = { identifier = "version";      ascending = true;  index = 8; visible = false; width = 75; };
        comments     = { identifier = "comments";     ascending = true;  index = 9; visible = false; width = 300; };
      };
    };
    loginwindow.LoginwindowText = "The way is shut. It was made by those who are dead, and the Dead keep it, until the time comes. The way is shut.";
    screencapture.location = "/Users/${username}/Library/Mobile\ Documents/com~apple~CloudDocs/Screenshots";
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

# Machine name, passed in per host by the flake's mkDarwinSystem (matches the
# darwinConfigurations entry, so `darwin-rebuild switch --flake .#<name>`
# never renames a Mac).
  networking.hostName = hostname;
  networking.computerName = hostname;
  networking.localHostName = hostname;

# Login shell is the macOS system bash (/bin/bash) so a broken Nix store or
# activation can never lock us out of a terminal. ~/.bash_profile then execs
# Nix's newer bash — see ../home/shell.nix. The bash config itself is managed
# by home-manager.
  environment.shells = [ "/run/current-system/sw/bin/bash" ];
  environment.systemPackages = [ pkgs.bash ];
  users.users.${username} = {
    shell = "/bin/bash";
    home = "/Users/${username}";
  };

# nix-darwin only applies users.users.<name>.shell to accounts it creates, so
# set the login shell on the existing account ourselves. Idempotent.
  system.activationScripts.postActivation.text = ''
    current="$(dscl . -read /Users/${username} UserShell | awk '{print $2}')"
    if [ "$current" != "/bin/bash" ]; then
      echo "setting login shell for ${username} to /bin/bash" >&2
      dscl . -create /Users/${username} UserShell /bin/bash
    fi
    # Finder only reads its view defaults at launch
    killall Finder 2>/dev/null || true
  '';

# System settings
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  system.primaryUser = username;
}
