# hosts/myVictus/hardware-configuration.nix
#
# PLACEHOLDER. Replace everything below the imports with the output of
#   nixos-generate-config --show-hardware-config
# run on the laptop (disk UUIDs/LUKS devices are machine-specific). Keep the
# amd-common.nix import. The assertion makes a build fail with a clear message
# until this has been done; delete it when you replace the file.

{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../amd-common.nix
  ];

  assertions = [{
    assertion = false;
    message = "hosts/myVictus/hardware-configuration.nix is still the placeholder; paste in `nixos-generate-config --show-hardware-config` output from the laptop.";
  }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
