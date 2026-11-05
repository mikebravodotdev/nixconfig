# hosts/bigGuy/default.nix
# System layer for bigGuy on NixOS. Replaces the apt packages and
# scripts/install-linux-desktop-packages.sh used on Debian. Not yet built or
# booted: evaluates, but see docs/linux-desktop.md for what is untested.

{ pkgs, username, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "bigGuy";
  time.timeZone = "America/New_York"; # adjust if wrong
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "26.05";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "podman" ];
  };
  networking.networkmanager.enable = true;

  # Desktop session: greetd -> uwsm -> Hyprland.
  programs.hyprland = { enable = true; withUWSM = true; };
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --cmd 'uwsm start hyprland-uwsm.desktop'";
      user = "greeter";
    };
  };
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
