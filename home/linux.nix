# home/linux.nix
# Linux-only (NixOS on bigGuy) bits: desktop integration, fonts, and GUI apps
# — the Linux counterpart to ../darwin/homebrew.nix. The Hyprland desktop
# itself (compositor, Quickshell, terminals, theming) is ./desktop.nix.

{ config, pkgs, lib, ... }:

{
  imports = [ ./appimages ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    # Fonts (on macOS these come from Homebrew casks)
    fonts.fontconfig.enable = true;

    # Flatpak: for GUI apps with no nixpkgs package and no squashfs AppImage.
    # hosts/bigGuy's services.flatpak.enable provides the portal units,
    # D-Bus activation and the flatpak binary itself.
    services.flatpak = {
      enable = true;
      remotes = lib.mkOptionDefault [
        { name = "flathub"; location = "https://flathub.org/repo/flathub.flatpakrepo"; }
      ];
      packages = [
        # ProtonPlus only ships a DwarFS-packed AppImage, which nixpkgs'
        # appimageTools can't extract (squashfs only).
        "com.vysp3r.ProtonPlus"

        # Lutris. Steam itself is native (programs.steam in hosts/bigGuy).
        "net.lutris.Lutris"
      ];
    };

    home.packages = [
      pkgs.nerd-fonts.hack
      pkgs.nerd-fonts.fira-code
      pkgs.hack-font
      pkgs.fira-code

      # Needed for Neovim's clipboard = "unnamedplus" under Wayland
      pkgs.wl-clipboard

      # Claude Code CLI.
      pkgs.claude-code

      # Homebrew brews / CLI casks on macOS
      pkgs.dart

      # GUI apps with no official AppImage. (Apps that do ship one are
      # pinned in ./appimages; Chromium is a system package in hosts/bigGuy
      # since it's the default browser the keybinds launch.)
      # Browsers
      pkgs.firefox
      pkgs.firefox-devedition
      pkgs.google-chrome
      pkgs.brave
      pkgs.microsoft-edge

      # Communication
      pkgs.element-desktop
      pkgs.jami
      pkgs.signal-desktop
      pkgs.slack
      pkgs.telegram-desktop

      # Development
      pkgs.podman-desktop
      pkgs.vscode
      pkgs.zed-editor

      # Productivity
      pkgs.libreoffice # its AppImages are unofficial builds
      pkgs.obs-studio
      pkgs.vlc
      pkgs.dropbox
    ];

    # Not managed here:
    # - 1Password, Keybase, Steam, Chromium: system-level installs in
    #   hosts/bigGuy/default.nix (browser integration, polkit, FUSE, udev
    #   rules need that layer, not home-manager).
    # - No Linux build at all: UTM, CodeRunner, Rectangle, Alfred, AppCleaner,
    #   BetterDisplay, DaisyDisk, Office, Acrobat Reader, Google Drive,
    #   Perplexity, Gemini, Grok, Twist, Vorssaint, OpenLogi, OpenVPN Connect
    #   (use openvpn3 instead).
  };
}
