# hosts/myVictus/default.nix
# myVictus: HP Victus laptop, Ryzen 7 7535HS (Radeon 680M iGPU) + discrete
# Radeon RX 6550M. The desktop is in ../desktop-common.nix; this file is only
# what is specific to this machine.

{ ... }:

{
  imports = [ ../desktop-common.nix ./hardware-configuration.nix ];

  networking.hostName = "myVictus";
  # Set this to the NixOS release you actually install from (the value
  # nixos-generate-config wrote into /etc/nixos/configuration.nix).
  system.stateVersion = "26.05";

  # --- Hybrid graphics (iGPU + dGPU, both amdgpu) --------------------------
  # No PRIME/NVIDIA-style module is needed: both GPUs use the same driver.
  # The iGPU drives the internal panel, and the dGPU wakes (runtime PM) only
  # for apps that ask for it:
  #   DRI_PRIME=1 <app>        run one app on the dGPU
  #   Steam: set a game's launch options to `DRI_PRIME=1 %command%`
  # To keep the compositor itself on the iGPU (saves battery, avoids the dGPU
  # waking for the desktop), find the iGPU's stable path after install:
  #   ls -l /dev/dri/by-path/        (the card at PCI 0000:XX:00.0 that is the 680M)
  # and then uncomment, substituting the by-path name (colons escaped as \:):
  #
  # environment.sessionVariables.AQ_DRM_DEVICES =
  #   "/dev/dri/by-path/pci-0000\\:XX\\:00.0-card";

  # --- Laptop power behavior ------------------------------------------------
  # power-profiles-daemon comes from amd-common.nix; upower from desktop-common.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore"; # lid closed with an external monitor
    HandlePowerKey = "suspend";
  };
  services.upower = {
    percentageLow = 15;
    percentageCritical = 7;
    percentageAction = 4;
    criticalPowerAction = "Hibernate";
  };
}
