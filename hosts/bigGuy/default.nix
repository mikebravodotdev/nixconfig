# hosts/bigGuy/default.nix
# bigGuy: Ryzen 9 9900X + Radeon RX 7900 desktop on an OLED monitor. The
# desktop itself is in ../desktop-common.nix; this file is only what is
# specific to this machine.

{ ... }:

{
  imports = [ ../desktop-common.nix ./hardware-configuration.nix ];

  networking.hostName = "bigGuy";
  system.stateVersion = "26.05";
}
