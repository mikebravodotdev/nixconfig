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

        # Gaming. The Flatpak Steam is the "Steam" ProtonPlus must target; its
        # Proton builds live in ~/.var/app/com.valvesoftware.Steam/data/Steam/
        # compatibilitytools.d. System-level prerequisite (not manageable
        # here): `sudo apt install steam-devices` for /dev/uinput access.
        "com.valvesoftware.Steam"
        "net.lutris.Lutris"
      ];

      # Steam's web UI draws the pointing-hand cursor; use the plain arrow
      # (theme created by home.activation below).
      overrides."com.valvesoftware.Steam".Environment.XCURSOR_THEME = "plain-arrow";
    };

    # Files inside the Steam Flatpak's sandbox home must be real files: the
    # sandbox can't follow symlinks into /nix/store, so no home.file here.
    # "plain-arrow" = Adwaita with every hand cursor replaced by the arrow;
    # the GTK setting is what Steam's Chromium UI actually reads.
    home.activation.steamPlainCursor = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      steam="$HOME/.var/app/com.valvesoftware.Steam"
      theme="$steam/.local/share/icons/plain-arrow"
      run mkdir -p "$theme/cursors" "$steam/.config/gtk-3.0" "$steam/.config/gtk-4.0"
      run install -m 644 ${pkgs.adwaita-icon-theme}/share/icons/Adwaita/cursors/left_ptr "$theme/cursors/left_ptr"
      for n in pointer hand1 hand2 pointing_hand \
               e29285e634086352946a0e7090d73106 9d800788f1b08800ae810202380a0822; do
        run ln -sfn left_ptr "$theme/cursors/$n"
      done
      printf '[Icon Theme]\nName=plain-arrow\nInherits=Adwaita\n' > "$theme/index.theme"
      for v in 3.0 4.0; do
        printf '[Settings]\ngtk-cursor-theme-name=plain-arrow\ngtk-cursor-theme-size=24\n' \
          > "$steam/.config/gtk-$v/settings.ini"
      done
    '';
    
    # Flatpak's portal/session-helper user units + D-Bus activation. Steam's
    # Flatpak refuses to start without org.freedesktop.portal.Flatpak, which
    # Debian would normally get from a host flatpak package.
    systemd.user.packages = [ pkgs.flatpak ];

    # The session bus doesn't scan ~/.nix-profile/share/dbus-1/services, only
    # XDG_DATA_HOME, so link the activation file there.
    xdg.dataFile."dbus-1/services/org.freedesktop.portal.Flatpak.service".source =
      "${pkgs.flatpak}/share/dbus-1/services/org.freedesktop.portal.Flatpak.service";

    home.packages = [
      # On PATH so exported Flatpak .desktop entries (`flatpak run …`) launch;
      # Debian has no host flatpak. Same package nix-flatpak installs apps with.
      pkgs.flatpak

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
