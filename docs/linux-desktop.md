# Linux desktop (bigGuy): Hyprland + Quickshell

This repo is the authority for the Linux desktop. The machine is Debian 13
running Hyprland 0.55 (Lua config) and a shell written in Quickshell 0.3 (QML)
that replaces the usual bar, launcher, notification daemon, lock screen and so
on. Everything is plain files under `dotfiles/linux/`.

It can also run on **NixOS**: `nixosConfigurations.bigGuy` (`hosts/`) is the
system layer, with home-manager as a module reusing `home/`. The config files
are identical on both; only the system layer differs. bigGuy was reinstalled
to NixOS on 2026-11-05; that is now the system in use.

The first `nixos-rebuild switch --flake .#bigGuy` booted into a working
Hyprland session (greetd/ReGreet, hypridle/hyprlock lock+unlock, uwsm env all
worked) but two things were missing because they'd only ever been checked by
`nix flake check`, not by actually logging in: `pkgs.claude-code` had been
dropped from `home/linux.nix` on the assumption Debian's apt-installed
`claude-desktop` covered it — it doesn't, and NixOS has no apt either, so
`claude` was on no PATH anywhere; and `services.keybase.enable` only
installs the daemon, so its self-written
`~/.config/autostart/keybase_autostart.desktop` (`Exec=... run_keybase`)
failed with exit 127 until `pkgs.keybase-gui` was added. Both are fixed now.
Still unverified: whether the Quickshell shell's QML imports (Qt5Compat,
WebP) actually render a bar/panels, as opposed to Hyprland just coming up
bare — nothing in the systemd journal distinguishes the two since Quickshell
isn't a systemd unit.

## What comes from where

| Piece | Source |
|---|---|
| Hyprland, hypridle/hyprlock, Quickshell, portals, greetd/uwsm, Qt modules | **Debian:** apt (`scripts/install-linux-desktop-packages.sh`). They need system integration (session, PAM, GPU). **NixOS:** `hosts/bigGuy/default.nix`. |
| Their configuration, the shell itself, helper scripts | **this repo** (`dotfiles/linux/`), linked in by `home/desktop.nix` |
| Hack Nerd Font, Nerd Font symbols (icons) | **Nix** (`home/linux.nix`, `home/desktop.nix`) |
| Theme palettes and wallpapers | **Nix**: the `omarchy` flake input (MIT, pinned), filtered in `home/desktop.nix` |
| Generated state (current theme, notification history, launcher usage, the `Super+K` cheat sheet's keybind list) | `~/.local/state/quickshell/`, never tracked |

Config files are linked **by reference to the checkout** (`desktop.repoPath`,
default `~/Code/nixconfig`), not copied into the Nix store. So the file in
`~/.config` *is* the repo file: edit it, reload, `git diff` shows the change,
no `home-manager switch` needed for a tweak.

| Repo path | Lands at |
|---|---|
| `dotfiles/linux/hypr/{hyprland.lua,conf/,hypridle.conf,hyprlock.conf}` | `~/.config/hypr/` |
| `dotfiles/linux/quickshell/{shell.qml,common,components,panels,services}` | `~/.config/quickshell/` |
| `dotfiles/linux/kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| `home/desktop.nix` (generated) | `~/.config/foot/foot.ini` |
| `dotfiles/linux/fontconfig/fonts.conf` | `~/.config/fontconfig/fonts.conf` |
| `dotfiles/linux/bin/*` | `~/.local/bin/` |
| omarchy input, filtered | `~/.config/quickshell/themes/` |

## Setting up a fresh machine

### NixOS

1. Install NixOS (UEFI, systemd-boot). Replace
   `hosts/<name>/hardware-configuration.nix` with the output of
   `nixos-generate-config` for that machine; `hosts/bigGuy`'s UUIDs only fit
   its current disk. For another AMD machine, copy `hosts/bigGuy/` and import
   `hosts/amd-common.nix` from its hardware file.
2. Clone this repo to `~/Code/nixconfig` (the config files are symlinked to
   it), then `sudo nixos-rebuild switch --flake .#bigGuy`. That installs the
   desktop, sets up greetd/uwsm and applies home-manager.
3. Log in. Hyprland's autostart (`hypr/conf/autostart.lua`) runs
   `theme-apply --init` on first login, applying the default theme (Retro 82).

Built and booted on bigGuy's hardware; see the note above for what that first
boot caught and fixed. Still unconfirmed: whether the Quickshell QML imports
(Qt5Compat, WebP) actually resolve and render the bar/panels — check for a
`quickshell` process and the bar on screen after logging in.

### Debian

1. Install Debian 13, enable `trixie-backports`, and set up greetd to start the
   session (`/etc/greetd/config.toml`, not managed here):
   ```toml
   [terminal]
   vt = 1
   [default_session]
   command = "/usr/sbin/agreety --cmd 'uwsm start hyprland.desktop'"
   user = "_greetd"
   ```
2. `scripts/install-linux-desktop-packages.sh` (add `-s` to simulate).
3. Install Nix, clone this repo to `~/Code/nixconfig`, then:
   ```sh
   nix run home-manager -- switch -b hm-backup --flake .#mikebravo@bigGuy
   ```
   `-b hm-backup` moves any existing real files out of the way (the first time
   on a machine that was configured by hand). The first run also adds the
   `omarchy` input to `flake.lock`: commit that. Afterwards `home-manager switch
   --flake .` is enough. Run the one-time `non-nixos-gpu-setup` it prints.
4. Log in. Hyprland's autostart (`hypr/conf/autostart.lua`) runs
   `theme-apply --init` on first login, applying the default theme (Retro 82).

The first switch also pulls the pinned Omarchy source (~210 MB) for the themes.
Fonts installed by hand into `~/.local/share/fonts` are then redundant and can
be deleted.

## Day to day

| Changed | Reload |
|---|---|
| QML under `quickshell/` | restart the shell: `pkill quickshell; quickshell &` (it logs errors to the terminal) |
| `hypr/*.lua`, `hypridle.conf` | `hyprctl reload` (`Super+Ctrl+Esc`), `hyprctl configerrors` lists mistakes |
| `kitty.conf` | `pkill -USR1 kitty` |
| `foot.ini`, fontconfig | Nix side: `home-manager switch`; new windows pick it up |
| Size of everything in the panels | `Theme.uiScale` in `quickshell/common/Theme.qml` |

## Themes

`theme-apply <name>` applies a palette everywhere: the shell (it watches
`state.json`), Hyprland borders, kitty, foot and the hyprlock colors.
`theme-apply --list` prints the themes, `--background <file>` sets the
wallpaper. The switcher UI is `Super+Ctrl+T` (themes) and `Super+Ctrl+W`
(backgrounds). Your own: `~/.config/quickshell/backgrounds/<theme>/` (one
theme) or `~/Pictures/Wallpapers/` (all). Open foot windows keep their old
colors until restarted (foot 1.21 can't reload them).

## Keybindings

Super is the main modifier. The full list is in `hypr/conf/bindings.lua`.

- **Apps:** `Super+Return` terminal, `Super+Shift+Return` browser, `Super+Shift+F`
  files, `Super+Space` launcher (apps, calculator, system commands,
  `>cmd` to run a shell command), `Super+Ctrl+V` clipboard history.
- **Windows:** `Super+W`/`Q` close, `T` float, `F` fullscreen, `J` split, `G` group,
  arrows focus, `Shift+arrows` swap, `Super+1..0` workspaces (`Shift` moves a window),
  `Super+S` scratchpad, `` Super+` `` drop-down terminal, `Alt+Tab` cycle.
- **Clipboard:** `Super+C/V/X/A` work everywhere, including terminals.
- **Shell:** `Super+K` keybinding cheat sheet, `Super+Esc` system menu, `Super+Ctrl+L`
  lock, `Super+Ctrl+T`/`W` themes and backgrounds, `Super+,` dismiss a toast,
  `Super+Shift+Alt+,` notification history, `Super+Ctrl+Alt+,` do not disturb,
  `Super+Shift+Space` toggle bar.
- **Capture:** `Print` region, `Shift+Print` screen, `Ctrl+Print` window,
  `Super+Print` color picker, `Super+Ctrl+Print` OCR, `Alt+Print` record.

## Controlling the shell from scripts

`quickshell ipc call <target> <function>`:
`launcher` toggle/present/dismiss/query "text", `clipboard` and `system`
toggle/present/dismiss, `appearance` toggleTheme/toggleBackground/dismiss,
`cheatsheet` toggle/present/dismiss,
`panels` toggle `audio|network|bluetooth|power|calendar|notifications|battery` / close,
`notifications` dismissAll/dismissOne/toggleDnd/clearHistory, `bar` toggle,
`lock` lock/isLocked. (`battery` mock/peripherals/off previews the battery UI
without one.) Avoid naming an IPC function `show` or `hide`: Quickshell treats
them as reserved and silently ignores the call.

## The lock screen

`lock-screen` locks with the shell's ext-session-lock surface (PAM service
`hyprlock`) and falls back to `hyprlock` when the shell isn't running, so the
screen is never left unlocked. hypridle calls it before sleep and after 5
minutes idle. There is no unlock command: only the password unlocks.

If the shell dies while locked, the session stays locked. From another TTY
(`Ctrl+Alt+F2`): log in, `pkill quickshell`, switch back to the graphical TTY
and run `hyprlock`. `allow_session_lock_restore` (in `looknfeel.lua`) lets it
take the lock over. This recovery path has not been exercised.

## Gaming (Steam, Lutris, ProtonPlus)

**On NixOS** Steam is native (`programs.steam`, with the udev rules from
`hardware.steam-hardware`); Lutris and ProtonPlus are Flatpaks, and everything
below about the Flatpak Steam does not apply.

**On Debian** all three are Flatpaks (`home/linux.nix`). Debian has no host
`flatpak`, so the config also supplies what a distro package normally would:

- `pkgs.flatpak` on `PATH`, and `~/.local/share/flatpak/exports/share` in
  `XDG_DATA_DIRS` (`hypr/conf/env.lua`), so the launcher lists the apps.
- The portal's systemd units and D-Bus activation file. Steam's Flatpak won't
  start without `org.freedesktop.portal.Flatpak`, and the session bus only
  scans `XDG_DATA_HOME`, not `~/.nix-profile`.
- A `plain-arrow` cursor theme plus GTK setting inside Steam's sandbox, because
  Steam's web UI otherwise shows a pointing hand. Those are real files written
  by `home.activation`; the sandbox can't follow symlinks into `/nix/store`.

Not in Nix: `sudo apt install steam-devices` (udev rules; without `/dev/uinput`
access Steam's Flatpak aborts on a warning dialog). ProtonPlus must install
builds for the *Flatpak* Steam, i.e. into
`~/.var/app/com.valvesoftware.Steam/data/Steam/compatibilitytools.d`; a stray
`~/.local/share/Steam` makes it target a native Steam instead. The RX 7900
already uses Mesa RADV (backports), so no driver change is needed.

## Known gaps

Built and checked on this (desktop) machine, but not on real hardware or by
hand: the battery widget against a real battery (only simulated), Bluetooth
pairing, connecting to a Wi-Fi network, the lock screen's wrong-password
animation, idle locking through hypridle, and the light themes.

The NixOS `nixos-rebuild switch --flake .#bigGuy` on bigGuy itself (2026-11-05)
is the first real build+switch, and is covered above. Still not covered:
an actual `home-manager switch -b hm-backup --flake .#mikebravo@bigGuy` on
Debian — that path remains eval-only.
