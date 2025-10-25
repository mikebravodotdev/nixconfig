# homebrew.nix
{ homebrew-core, homebrew-cask,... }:

{
  homebrew = {
    enable = true;
    user = "mikebravo";

    # Taps (third-party repositories)
    taps = [
      "homebrew/homebrew-core"
      "homebrew/homebrew-cask"
    ];

    # Formulas (command-line applications)
    brews = [
      "dart-sdk"
    ];

    # Casks (GUI Applications, Fonts, etc.)
    casks = [
      # Browsers
      "google-chrome"
      "google-chrome@dev"
      "librewolf"
      "firefox@developer-edition"
      "ungoogled-chromium"

      # Communication
      "element"
      "jami"
      "jitsi-meet"
      "session"
      "signal"
      "signal@beta"
      "slack"
      "telegram"
      "twist"

      # Development & Terminals
      "balenaetcher"
      "ghostty"
      "iterm2"
      "lapce"
      "lm-studio"
      "podman-desktop"
      "utm"
      "visual-studio-code"
      "wezterm"
      "zed"

      # Productivity
      "audacity"
      "libreoffice"
      "logseq"
      "obs"
      "vlc"
      "standard-notes"
      "todoist"

      # Proton Suite
      "proton-drive"
      "proton-mail"
      "proton-mail-bridge"
      "proton-pass"
      "protonvpn"

      # Fonts
      "font-fira-code"
      "font-fira-code-nerd-font"
      "font-hack"
      "font-hack-nerd-font"
    ];
  };
}
