# home/linux.nix
# Linux-only (non-NixOS: Debian 13 on bigGuy) bits: desktop integration, fonts,
# and GUI apps — the Linux counterpart to ../darwin/homebrew.nix. The Hyprland
# desktop itself (compositor, Quickshell, terminals, theming) is ./desktop.nix.

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

    # Flatpak: for GUI apps with no nixpkgs package and no squashfs AppImage.
    services.flatpak = {
      enable = true;
      remotes = lib.mkOptionDefault [
        { name = "flathub"; location = "https://flathub.org/repo/flathub.flatpakrepo"; }
      ];
      packages = [
        # ProtonPlus only ships a DwarFS-packed AppImage, which nixpkgs'
        # appimageTools can't extract (squashfs only).
        "com.vysp3r.ProtonPlus"
      ];
    };

    home.packages = [
      pkgs.nerd-fonts.hack
      pkgs.nerd-fonts.fira-code
      pkgs.hack-font
      pkgs.fira-code

      # Needed for Neovim's clipboard = "unnamedplus" under Wayland
      pkgs.wl-clipboard

      # Homebrew brews / CLI casks on macOS
      pkgs.dart

      # GUI apps with no official AppImage. (Apps that do ship one are
      # pinned in ./appimages; Firefox and Chromium come from the distro.)
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
    # - 1Password / 1password-cli, Keybase: install from the vendor's own apt
    #   repo — browser integration, polkit and FUSE need system-level installs.
    # - Claude desktop: installed from apt on bigGuy (claude-desktop).
    # - No Linux build: UTM, CodeRunner, Rectangle, Alfred, AppCleaner,
    #   BetterDisplay, DaisyDisk, Office, Acrobat Reader, Google Drive,
    #   Perplexity, Gemini, Grok, Twist, Vorssaint, OpenLogi.
    #   OpenVPN Connect → use openvpn3 from OpenVPN's apt repo.
  };
}
