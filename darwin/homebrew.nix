# darwin/homebrew.nix
# macOS-only. Linux equivalents of these casks live in ../home/linux.nix
# (nixpkgs) and ../home/appimages where a Linux build exists.
{ lib, username, hostname, ... }:

{
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";   # intentional: anything not declared here gets removed
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
      "helium-browser"

      # Communication
      "discord"
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
      "cursor"

      # Productivity
      # "audacity"
      "screenflow"
      "audacity@3"
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
      "grok-build"
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
    ]
    # Gaming: Atlas only
    ++ lib.optionals (hostname == "Atlas") [
      "steam"
      "battle-net"
    ];
  };
}
