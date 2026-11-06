# Setting up myVictus (HP Victus, Ryzen 7 7535HS + RX 6550M)

## At a glance

The hardware config for this laptop is already committed in this directory
(`hardware-configuration.nix`, generated 2026-11-05). On the same laptop and
disk layout you can skip step 3. Start here after installing NixOS:

```sh
nix-shell -p git gh        # temporary shell with git and gh
gh auth login              # only needed while the repo is private
git clone <repo-url> ~/Code/nixconfig
cd ~/Code/nixconfig

# Only if the disk layout changed or you are setting up a different machine:
nixos-generate-config --show-hardware-config > hosts/myVictus/hardware-configuration.nix
git add hosts/myVictus/hardware-configuration.nix   # flakes only see tracked files

exit                       # back to the normal prompt
sudo nixos-rebuild switch --flake .#myVictus
```

Notes:

- `gh auth login` works on a bare console. Choose GitHub.com, HTTPS, "Login with
  a web browser". It prints a code and a URL to open on another device (such as
  your phone); no browser is needed on the laptop. A public repo needs no login
  to clone over HTTPS.
- Stage the hardware file **before** you `exit`: the flake only sees files git
  tracks, so an unstaged file fails with "path not tracked".
- Check `stateVersion` (step 4) before the first rebuild.
- Flakes are not enabled on a fresh install. `nixos-rebuild --flake` normally
  enables them for that command; if you get an "experimental feature" error,
  add `--option experimental-features "nix-command flakes"`.
- If the build complains that `git` is missing, rerun it inside
  `nix-shell -p git`.
- The first build is slow: it downloads a lot and pulls the pinned Omarchy
  source (~210 MB).

The sections below explain each step.

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
