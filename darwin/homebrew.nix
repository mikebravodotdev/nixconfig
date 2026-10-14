# darwin/homebrew.nix
# macOS-only. Linux equivalents of these casks live in ../home/linux.nix
# (nixpkgs) and ../home/appimages where a Linux build exists.
{ homebrew-core, homebrew-cask, username, ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";   # or "uninstall";
    user = username;

    taps = [ ];

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
      "keybase"
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
      "openvpn-connect"
      # "wezterm"
      "zed"
      "coderunner"

      # Productivity
      "audacity"
      "libreoffice"
      "logseq"
      "obs"
      "obsidian"
      "vlc"
      "rectangle"
      "alfred"
      "appcleaner"
      "betterdisplay"
      "dropbox"
      "google-drive"
      "openlogi"
      "microsoft-office-businesspro"
      "adobe-acrobat-reader"
      # "standard-notes"
      # "todoist"

      # AI
      "google-gemini"
      "grok-bot"
      "claude"
      "claude-code"
      "perplexity"

      # Security
      "1password"
      "1password-cli"

      #System Tools
      "daisydisk"
      # "carbon-copy-cloner"
      "vorssaint"
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
