# home/linux.nix
# Linux-only (non-NixOS, e.g. Fedora) bits: desktop integration, fonts, and
# GUI apps — the Linux counterpart to ../darwin/homebrew.nix.

{ pkgs, lib, ... }:

{
  imports = [ ./appimages ];

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    # XDG data dirs, desktop entries, locale, and GPU drivers for Nix-built
    # GUI apps (e.g. Ghostty) on a non-NixOS distro. After the first switch,
    # home-manager prints a one-time `sudo .../non-nixos-gpu-setup` to run.
    targets.genericLinux.enable = true;

    # Fonts (on macOS these come from Homebrew casks)
    fonts.fontconfig.enable = true;

    home.packages = [
      pkgs.nerd-fonts.hack
      pkgs.nerd-fonts.fira-code
      pkgs.hack-font
      pkgs.fira-code

      # Needed for Neovim's clipboard = "unnamedplus" under Wayland (Plasma)
      pkgs.wl-clipboard

      # Homebrew brews / CLI casks on macOS
      pkgs.dart
      pkgs.claude-code

      # GUI apps with no official AppImage. (Apps that do ship one are
      # pinned in ./appimages; Firefox ships with Fedora.)
      # Browsers
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
    # - 1Password / 1password-cli, Keybase: install from their dnf repos —
    #   browser integration, polkit and FUSE need system-level installs.
    # - No Linux build: UTM, CodeRunner, Rectangle, Alfred, AppCleaner,
    #   BetterDisplay, DaisyDisk, Office, Acrobat Reader, Google Drive,
    #   Claude desktop, Perplexity, Gemini, Grok, Twist, Vorssaint, OpenLogi.
    #   OpenVPN Connect → use openvpn3 from dnf.
  };
}
