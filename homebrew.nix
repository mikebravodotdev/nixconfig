# homebrew.nix

{ homebrew-core, homebrew-cask,... }:
{
  homebrew = {
    # Install Homebrew under the default prefix
    enable = true;

    # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
    # enableRosetta = true;

    # User owning the Homebrew prefix
    user = "mikebravo";

    # Automatically migrate existing Homebrew installations
    # autoMigrate = true;
    # Optional: Declarative tap management
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
    ];

    # Optional: Enable fully-declarative tap management
    #
    # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
    # mutableTaps = false;
    # You can also manage taps, casks, and formulas here
    #taps = [
    #  "homebrew/services"
    #];
    casks = [
      "ungoogled-chromium"
      "google-chrome"
      "google-chrome@dev"
      "signal"
      "signal@beta"
      "session"
      "twist"
      "obs"
      "jami"
      "ghostty"
      "libreoffice"
      "proton-pass"
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "protonvpn"
      "jitsi-meet"
      "font-fira-code"
      "font-fira-code-nerd-font"
      "font-hack"
      "font-hack-nerd-font"
      "todoist"
      "standard-notes"
      "balenaetcher"
    ];
  };
}
