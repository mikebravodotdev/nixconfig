# hosts/bigGuy/default.nix
# bigGuy: Ryzen 9 9900X + Radeon RX 7900 desktop on an OLED monitor. The
# desktop itself is in ../desktop-common.nix; this file is only what is
# specific to this machine.

{ ... }:

{
  imports = [ ../desktop-common.nix ./hardware-configuration.nix ];

  networking.hostName = "bigGuy";
  system.stateVersion = "26.05";

  # ReGreet: the default theme (Adwaita, light) renders the greeter as a blinding white
  # screen. Switch GTK to its dark palette and force the toplevel window
  # itself to pure black (the "background" widget is just an unset
  # gtk::Picture, so the window's own background shows through it) for the
  # OLED monitor.
  services.displayManager.regreet.settings.GTK.application_prefer_dark_theme = true;
  services.displayManager.regreet.extraCss = ''
    window {
      background-color: #000000;
    }
  '';
}
