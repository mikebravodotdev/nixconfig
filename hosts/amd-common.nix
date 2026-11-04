# hosts/amd-common.nix
# Hardware bits shared by every AMD CPU + AMD GPU machine (desktop or laptop).
# Machine-specific disks/filesystems live in hosts/<name>/hardware-configuration.nix
# (generate with `nixos-generate-config` on the target; don't copy UUIDs between machines).

{ config, lib, pkgs, ... }:

{
  # Microcode + non-free firmware (amdgpu, wifi, bluetooth all need it).
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot.kernelModules = [ "kvm-amd" ];
  boot.initrd.kernelModules = [ "amdgpu" ]; # early KMS: native resolution/10-bit from boot

  # Recent Zen CPUs: the amd-pstate driver in active (EPP) mode.
  boot.kernelParams = [ "amd_pstate=active" ];

  # Open-source stack: in-kernel amdgpu + Mesa (RADV/radeonsi). No NVIDIA.
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Proton
    extraPackages = with pkgs; [ rocmPackages.clr.icd ]; # OpenCL; drop if unwanted
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Laptops and desktops both benefit; harmless on a desktop.
  services.power-profiles-daemon.enable = lib.mkDefault true;
}
