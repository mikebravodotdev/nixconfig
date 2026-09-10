# homebrew.nix
{ homebrew-core, homebrew-cask,... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";   # or "uninstall";
    user = "mikebravo";

    # Formulas (command-line applications)
    brews = [
      "dart-sdk"
      "brew-gem"
    ];

    # Casks (GUI Applications, Fonts, etc.)
    casks = [
      # Browsers
      "google-chrome"
      "google-chrome@dev"
      "librewolf"
      "firefox@developer-edition"
      "firefox"
      "brave-browser"
      "microsoft-edge"
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
      # "balenaetcher"
      "ghostty"
      # "iterm2"
      # "lapce"
      "lm-studio"
      "podman-desktop"
      "utm"
      "visual-studio-code"
      # "wezterm"
      "zed"
      "coderunner"

      # Productivity
      "audacity"
      "libreoffice"
      "logseq"
      "obs"
      "vlc"
      "rectangle"
      "alfred"
      "appcleaner"
      "betterdisplay"
      "dropbox"
      "google-drive"
      "logi-options+"
      "microsoft-office-businesspro"
      # "standard-notes"
      # "todoist"

      # AI
      "google-gemini"
      "grok-bot"

      # Security
      "1password"
      "1password-cli"

      # Proton Suite
      # "proton-drive"
      # "proton-mail"
      # "proton-mail-bridge"
      # "proton-pass"
      # "protonvpn"

      # Fonts
      "font-fira-code"
      "font-fira-code-nerd-font"
      "font-hack"
      "font-hack-nerd-font"
    ];
  };
}
