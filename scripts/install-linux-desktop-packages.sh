#!/usr/bin/env bash
# Installs the apt packages the Hyprland desktop needs on Debian 13 (trixie).
# Debian only: on NixOS the same list lives in hosts/bigGuy/default.nix.
# These can't come from Nix: the compositor, the lock screen's PAM stack, the
# greetd/uwsm session and the portals need system integration. Their
# *configuration* is in dotfiles/linux and wired up by home/desktop.nix.
# Needs trixie-backports enabled (Hyprland and Quickshell are only there).
#
#   scripts/install-linux-desktop-packages.sh            # install
#   scripts/install-linux-desktop-packages.sh -s         # simulate only
set -euo pipefail

packages=(
  # Session: compositor, login, idle/lock, portals
  hyprland hyprland-guiutils uwsm greetd tuigreet
  hypridle hyprlock hyprpaper hyprpicker hyprshutdown hyprsunset hyprpolkitagent
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils

  # The shell and what its QML imports (Shapes, Layouts, Qt5Compat blur) and
  # decodes (the theme wallpapers are WebP)
  quickshell
  qml6-module-qtquick qml6-module-qtquick-layouts qml6-module-qtquick-shapes
  qml6-module-qtquick-window qml6-module-qt5compat-graphicaleffects
  qt6-image-formats-plugins
  breeze-icon-theme fonts-noto-core

  # Apps the keybindings launch
  kitty foot nautilus chromium

  # Tools the scripts and bar widgets call
  grim slurp wl-clipboard cliphist wf-recorder tesseract-ocr jq python3
  libnotify-bin brightnessctl playerctl

  # Hardware and services the bar popups talk to
  pipewire-audio wireplumber network-manager bluez power-profiles-daemon upower
)

# Nautilus needs libxkbregistry0 at the same version as the backported
# libxkbcommon0 that Hyprland pulls in; without naming it, apt resolves to the
# stable one and fails with "held broken packages".
exec sudo apt install "$@" libxkbregistry0/trixie-backports "${packages[@]}"
