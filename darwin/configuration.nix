# darwin/configuration.nix
# macOS system layer (nix-darwin). Everything user-level and cross-platform
# — packages, shell, editor, dotfiles — lives in ../home instead.

{ self, pkgs, username, ... }:

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
    finder.FXPreferredViewStyle = "clmv";
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

# Machine name (matches the flake's darwinConfigurations entry).
  networking.hostName = "Hermes";
  networking.computerName = "Hermes";
  networking.localHostName = "Hermes";

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
  '';

# System settings
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 6;
  system.primaryUser = username;
}
