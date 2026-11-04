# hosts/bigGuy/default.nix
# System layer for bigGuy on NixOS. Replaces the apt packages and
# scripts/install-linux-desktop-packages.sh used on Debian.

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
  security.pam.services.hyprlock = { };
  security.polkit.enable = true;
  xdg.portal.enable = true;
  services.pipewire = { enable = true; alsa.enable = true; pulse.enable = true; };

  # Things Debian couldn't manage declaratively.
  services.flatpak.enable = true;
  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = { enable = true; polkitPolicyOwners = [ username ]; };
  virtualisation.podman.enable = true;
  services.keybase.enable = true;
}
