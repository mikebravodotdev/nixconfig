# Linux desktop (bigGuy): Hyprland + Quickshell

This repo is the authority for the Linux desktop. The machine is NixOS
(`nixosConfigurations.bigGuy`, `hosts/bigGuy/`) running Hyprland 0.55 (Lua
config) and a shell written in Quickshell 0.3 (QML) that replaces the usual
bar, launcher, notification daemon, lock screen and so on. The system layer
is `hosts/bigGuy/default.nix`; home-manager runs as a module reusing `home/`.
Everything else is plain files under `dotfiles/linux/`.

bigGuy was reinstalled from Debian to NixOS on 2026-11-05; NixOS is the only
Linux target this repo supports now.

The first `nixos-rebuild switch --flake .#bigGuy` booted into a working
Hyprland session (greetd/ReGreet, hypridle/hyprlock lock+unlock, uwsm env all
worked) but two things were missing because they'd only ever been checked by
`nix flake check`, not by actually logging in: `pkgs.claude-code` had been
dropped from `home/linux.nix`, so `claude` was on no PATH anywhere; and
`services.keybase.enable` only installs the daemon, so its self-written
`~/.config/autostart/keybase_autostart.desktop` (`Exec=... run_keybase`)
failed with exit 127 until `pkgs.keybase-gui` was added. Both are fixed now.
Quickshell's QML imports (Qt5Compat, WebP) do resolve and render the bar and
panels correctly — confirmed live, screenshots and all.

## What comes from where

| Piece | Source |
|---|---|
| Hyprland, hypridle/hyprlock, Quickshell, portals, greetd/uwsm, Qt modules | `hosts/bigGuy/default.nix` (they need system integration: session, PAM, GPU) |
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

1. Install NixOS (UEFI, systemd-boot). Replace
   `hosts/<name>/hardware-configuration.nix` with the output of
   `nixos-generate-config` for that machine; `hosts/bigGuy`'s UUIDs only fit
   its current disk. For another AMD machine, copy `hosts/bigGuy/` and import
   `hosts/amd-common.nix` from its hardware file.
2. Clone this repo to `~/Code/nixconfig` (the config files are symlinked to
   it), then `sudo nixos-rebuild switch --flake .#bigGuy`. That installs the
   desktop, sets up greetd/uwsm and applies home-manager. The first switch
   also pulls the pinned Omarchy source (~210 MB) for the themes.
3. Log in. Hyprland's autostart (`hypr/conf/autostart.lua`) runs
   `theme-apply --init` on first login, applying the default theme (Retro 82).

Built and booted on bigGuy's hardware; see the note above for what that first
boot caught and fixed.

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

Steam is native (`programs.steam` in `hosts/bigGuy/default.nix`, with the
udev rules from `hardware.steam-hardware`). Lutris and ProtonPlus are
Flatpaks (`home/linux.nix`); `hosts/bigGuy`'s `services.flatpak.enable`
provides the portal units, D-Bus activation and the `flatpak` binary they
need. The RX 7900 uses Mesa RADV, so no driver setup is needed beyond that.

## Known gaps

Built and checked on this (desktop) machine, but not on real hardware or by
hand: the battery widget against a real battery (only simulated), Bluetooth
pairing, connecting to a Wi-Fi network, the lock screen's wrong-password
animation, idle locking through hypridle, and the light themes.
