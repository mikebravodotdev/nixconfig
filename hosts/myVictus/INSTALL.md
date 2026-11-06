# Setting up myVictus (HP Victus, Ryzen 7 7535HS + RX 6550M)

## 1. Install NixOS

Boot the NixOS graphical or minimal ISO and install to the laptop. Choose UEFI
with systemd-boot (the default). Encrypt the disk if you want. Create the user
with the same username as in `flake.nix`.

Reboot into the fresh install and connect to the network.

## 2. Get the repo

The installed system may not have git yet, so use a temporary shell:

```sh
mkdir -p ~/Code && cd ~/Code
nix-shell -p git --run "git clone <your-repo-url> nixconfig"
cd nixconfig
```

The dotfiles are symlinked from `~/Code/nixconfig`, so it must live there.

## 3. Generate this machine's hardware config

```sh
nixos-generate-config --show-hardware-config > hosts/myVictus/hardware-configuration.nix
```

Then edit `hosts/myVictus/hardware-configuration.nix`:

- Add `../amd-common.nix` to the `imports` list.
- Remove the `assertions` placeholder block (it only existed in the old file,
  so it is already gone if you overwrote it as above).

Stage the file so the flake can see it:

```sh
git add hosts/myVictus/hardware-configuration.nix
```

## 4. Check `stateVersion`

```sh
grep stateVersion /etc/nixos/configuration.nix
```

Put that value in `system.stateVersion` in `hosts/myVictus/default.nix`.

## 5. Build and switch

```sh
sudo nixos-rebuild switch --flake .#myVictus
```

The first build also fetches the pinned Omarchy source (~210 MB). Reboot
afterwards, then log in through ReGreet and pick "Hyprland (uwsm)".

## 6. Pin the compositor to the iGPU (optional, saves battery)

```sh
ls -l /dev/dri/by-path/
```

Find the card for the Radeon 680M (`lspci | grep -i vga` shows which PCI
address is which). Uncomment `AQ_DRM_DEVICES` in `hosts/myVictus/default.nix`,
fill in that address, and rebuild with the command from step 5.

Run something on the discrete GPU with `DRI_PRIME=1 <app>`; for Steam use
`DRI_PRIME=1 %command%` as the launch option.

## 7. Commit

```sh
git add -A && git commit -m "myVictus: real hardware config"
```

Sign back in to 1Password, Keybase and Steam; those are not part of the repo.
