# hosts/bigGuy/hardware-configuration.nix
# Ryzen 9 9900X + Radeon RX 7900 (Navi 31) desktop, UEFI, NVMe.
# Two independent LUKS containers on nvme1n1, no LVM: p2 -> ext4 root,
# p3 -> swap. (nvme0n1 is an old/spare disk with a leftover Fedora install;
# it is not involved in booting this system and is left untouched.)
#
# The UUIDs below are THIS machine's today, as of the 2026-11-05 reinstall
# (KDE Plasma ISO, plain LUKS, no LVM). If you reinstall/repartition, replace
# this file with the output of `nixos-generate-config` (keep it as the
# authority for disks).

{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../amd-common.nix
  ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

  # Root: LUKS container directly holding ext4 (no LVM).
  boot.initrd.luks.devices."luks-db67ce62-4b3f-45ea-b525-605feba83803" = {
    device = "/dev/disk/by-uuid/db67ce62-4b3f-45ea-b525-605feba83803";
    allowDiscards = true; # TRIM through LUKS (NVMe); small metadata leak, usual trade-off
  };

  # Swap: its own separate LUKS container (not inside the root one).
  boot.initrd.luks.devices."luks-143e97b8-4e8c-4ed8-ac6a-5de2906538b3" = {
    device = "/dev/disk/by-uuid/143e97b8-4e8c-4ed8-ac6a-5de2906538b3";
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/mapper/luks-db67ce62-4b3f-45ea-b525-605feba83803";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F0DD-8227";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [
    { device = "/dev/mapper/luks-143e97b8-4e8c-4ed8-ac6a-5de2906538b3"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
