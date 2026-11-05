# hosts/bigGuy/default.nix
# System layer for bigGuy on NixOS. Replaces the apt packages and
# scripts/install-linux-desktop-packages.sh used on Debian. Built and boots
# into Hyprland (2026-11-05); see docs/linux-desktop.md for what's still
# unverified (the Quickshell QML imports in particular).

{ pkgs, username, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "bigGuy";
  time.timeZone = "America/New_York"; # adjust if wrong
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "26.05";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # keybase-gui bundles Electron 28 (EOL, multiple known CVEs) and is
  # blocked by nixpkgs' insecure-package check by default; allowed anyway
  # since we actually want the GUI (see services.keybase.enable below).
  # Re-pin the version string if a nixpkgs update bumps keybase-gui and this
  # starts failing again.
  nixpkgs.config.permittedInsecurePackages = [ "keybase-gui-6.5.1" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "podman" ];
  };
  networking.networkmanager.enable = true;

  # Desktop session: greetd -> ReGreet (graphical GTK greeter, runs in its
  # own cage/wlroots session). programs.hyprland.withUWSM registers a
  # "Hyprland (uwsm)" entry in /run/current-system/sw/share/wayland-sessions,
  # which ReGreet lists in its session dropdown automatically.
  programs.hyprland = { enable = true; withUWSM = true; };
  services.displayManager.regreet.enable = true;
  programs.hyprlock.enable = true;  # also installs the hyprlock PAM service
  services.hypridle.enable = true;
  security.polkit.enable = true;
  xdg.portal = {
    enable = true; # xdg-desktop-portal-hyprland comes with programs.hyprland
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  services.pipewire = { enable = true; alsa.enable = true; pulse.enable = true; };

  # The Nix equivalents of scripts/install-linux-desktop-packages.sh. Their
  # configuration is in dotfiles/linux, linked in by home/desktop.nix.
  environment.systemPackages = with pkgs; [
    # Session helpers
    hyprpaper hyprpicker hyprshutdown hyprsunset hyprpolkitagent hyprland-qtutils
    xdg-utils

    # The shell and what its QML imports / decodes (WebP wallpapers, icons)
    quickshell
    kdePackages.qt5compat
    kdePackages.qtimageformats
    kdePackages.breeze-icons
    noto-fonts

    # Apps the keybindings launch
    kitty foot nautilus chromium

    # Tools the scripts and bar widgets call
    grim slurp wl-clipboard cliphist wf-recorder tesseract jq python3
    libnotify brightnessctl playerctl

    # services.keybase.enable (below) only installs the CLI/daemon; on first
    # run it writes ~/.config/autostart/keybase_autostart.desktop with
    # `Exec=... run_keybase`, which comes from the GUI package and crashes
    # (exit 127) without it.
    keybase-gui
  ];

  # Services the bar popups talk to
  hardware.bluetooth.enable = true;
  services.upower.enable = true;

  # Things that had to be installed by hand on Debian.
  services.flatpak.enable = true;
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = { enable = true; polkitPolicyOwners = [ username ]; };
  virtualisation.podman.enable = true;
  services.keybase.enable = true;
}
