# hosts/bigGuy/hardware-configuration.nix
# Ryzen 9 9900X + Radeon RX 7900 (Navi 31) desktop, UEFI, NVMe.
# Modeled on bigGuy's current disk layout (Debian: LUKS -> LVM -> ext4 root + swap),
# but for NixOS the ESP is mounted at /boot (systemd-boot) and the separate
# ext4 /boot partition is not used.
#
# The UUIDs below are THIS machine's today. If you reinstall/repartition, replace this
# file with the output of `nixos-generate-config` (keep it as the authority for disks).

{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../amd-common.nix
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

  # LUKS container holding the LVM volume group.
  boot.initrd.luks.devices."cryptlvm" = {
    device = "/dev/disk/by-uuid/9bccb95d-156e-4437-a923-c59e1cda6551";
    allowDiscards = true; # TRIM through LUKS (NVMe); small metadata leak, usual trade-off
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/64e0c2d9-7187-4cda-a743-1a47ed7a90e9";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F544-3737";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/cfe5fe62-cfb7-426a-9b1e-7eae697fe39f"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
