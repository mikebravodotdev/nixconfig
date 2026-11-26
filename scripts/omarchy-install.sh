#!/usr/bin/env bash
# Install the nixconfig's Linux GUI apps, fonts and Ghostty setup natively on
# Omarchy (Arch / Arch Linux ARM), using pacman and the AUR instead of Nix.
#
# Mirrors: home/default.nix (Ghostty), home/linux.nix (fonts, browsers,
# communication, dev) and home/appimages/sources.json (AppImage apps, taken
# from the repos/AUR wherever a package exists).
#
# Usage: scripts/omarchy-install.sh [options]
#   -n, --dry-run            print what would happen, change nothing
#       --no-ghostty         skip the Ghostty theme and settings
#       --keep-omarchy-theme leave Omarchy's dynamic Ghostty theme include in
#                            place (it overrides CanadianShield's colors)
#       --no-packages        skip the app/font packages
#       --no-podman          skip the rootless Podman setup (below)
#       --slow               also install packages that compile from source
#                            for a long time (podman-desktop-git)
#   -h, --help
#
# Podman: replaces Omarchy's root Docker daemon with rootless Podman and
# podman-docker (a `docker` command that runs Podman), as in home/shell.nix.
# This REMOVES the `docker` package (pacman asks first); images and containers
# under /var/lib/docker are not migrated.
#
# Safe to re-run: installed packages are skipped, the Ghostty block is
# replaced in place, and ~/.config/ghostty/config is backed up first.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
arch="$(uname -m)"          # x86_64 or aarch64
dry=0 do_ghostty=1 do_pkgs=1 do_podman=1 keep_omarchy_theme=0 slow=0

while [ $# -gt 0 ]; do
  case $1 in
    -n|--dry-run) dry=1 ;;
    --no-ghostty) do_ghostty=0 ;;
    --keep-omarchy-theme) keep_omarchy_theme=1 ;;
    --no-packages) do_pkgs=0 ;;
    --no-podman) do_podman=0 ;;
    --slow) slow=1 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d;s/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

say() { printf '\033[1m==> %s\033[0m\n' "$*"; }
run() { if [ $dry -eq 1 ]; then printf '+ %s\n' "$*"; else "$@"; fi; }

# ---------------------------------------------------------------- packages --
# Anything here must exist for the machine's architecture. Packages that are
# x86_64-only (no aarch64 build in the Arch ARM / Omarchy repos or AUR) are
# added only on x86_64 and listed as skipped on ARM.
pkgs=()      # to install
skipped=()   # "name — reason"

add()  { pkgs+=("$@"); }
x86()  { # <pkg> <reason when not available>
  if [ "$arch" = x86_64 ]; then pkgs+=("$1"); else skipped+=("$1 — ${2:-x86_64 only}"); fi
}

# Fonts (home/linux.nix: Hack/Fira Code, plain and Nerd Font)
add ttf-hack-nerd ttf-firacode-nerd ttf-hack ttf-fira-code

# Browsers. Already native on Omarchy: firefox, chromium.
add google-chrome helium-browser-bin
x86 microsoft-edge-stable-bin       "no aarch64 build"
x86 firefox-developer-edition       "no aarch64 package (Mozilla's tarball only)"
x86 ungoogled-chromium-bin          "no aarch64 build"

# Communication. Already native: signal-desktop, slack-desktop.
add telegram-desktop jami-qt
x86 discord                         "no aarch64 build (use the web app)"
x86 element-desktop-bin             "no aarch64 build (use the web app)"
x86 session-desktop-bin             "no aarch64 build"
x86 jitsi-meet-desktop-bin          "no aarch64 build"

# Dev. Already native: cursor-bin, zed, ghostty.
add visual-studio-code-bin
[ $slow -eq 1 ] && add podman-desktop-git \
  || skipped+=("podman-desktop-git — source build is slow; pass --slow")

# Gaming (home/linux.nix Flatpaks, installed natively). Steam is already native.
add lutris protonplus

# Former AppImages, now repo/AUR packages. Already native: obsidian.
add audacity lmstudio-bin logseq-desktop-bin
x86 onlyoffice-bin                  "no aarch64 build"
# Not packaged anywhere: lmstudio-bionic, 0ad (use `pacman -S 0ad` on x86_64 only).

install_packages() {
  command -v yay >/dev/null || { echo "yay not found (Omarchy ships it)" >&2; exit 1; }

  local missing=() p
  for p in "${pkgs[@]}"; do
    pacman -Qq "$p" >/dev/null 2>&1 || missing+=("$p")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    say "All packages already installed"
  else
    say "Installing ${#missing[@]} packages: ${missing[*]}"
    # --needed: skip up-to-date; --noconfirm would hide AUR PKGBUILD review,
    # so prompts are left on.
    run yay -S --needed "${missing[@]}"
  fi

  if [ ${#skipped[@]} -gt 0 ]; then
    say "Skipped on $arch:"
    printf '    %s\n' "${skipped[@]}"
  fi
}

# ------------------------------------------------------------------ podman --
# Rootless Podman with a Docker-compatible CLI and API socket. podman-docker
# provides /usr/bin/docker (a wrapper around podman) and conflicts with the
# `docker` package, so Omarchy's root daemon goes away. "Sudoless" comes from
# running as your own user (user namespaces), not from the docker group, which
# is root-equivalent.
setup_podman() {
  say "Podman: rootless, docker-compatible"
  local uid sock cfgdir="${XDG_CONFIG_HOME:-$HOME/.config}"
  uid="$(id -u)"
  sock="/run/user/$uid/podman/podman.sock"

  # Rootless containers need subordinate uid/gid ranges (Omarchy sets these).
  if ! grep -q "^$USER:" /etc/subuid 2>/dev/null || ! grep -q "^$USER:" /etc/subgid 2>/dev/null; then
    run sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
  fi

  # The root daemon must stop before the package that owns it is replaced.
  if systemctl is-enabled docker.socket docker.service >/dev/null 2>&1 \
     || systemctl is-active docker.service >/dev/null 2>&1; then
    run sudo systemctl disable --now docker.socket docker.service
  fi

  if pacman -Qq podman-docker >/dev/null 2>&1; then
    run yay -S --needed podman podman-compose netavark aardvark-dns
  else
    echo "    pacman will ask to remove 'docker' (conflicts with podman-docker): answer y."
    run yay -S --needed podman podman-docker podman-compose netavark aardvark-dns
  fi

  # Short image names (`docker pull nginx`) need a search registry, as Docker
  # assumes Docker Hub. User-level so /etc stays package-owned.
  run mkdir -p "$cfgdir/containers/registries.conf.d"
  if [ $dry -eq 1 ]; then
    echo "+ write $cfgdir/containers/registries.conf.d/00-docker-hub.conf"
    echo "+ write $cfgdir/environment.d/podman.conf (DOCKER_HOST=unix://$sock)"
  else
    printf 'unqualified-search-registries = ["docker.io"]\n' \
      > "$cfgdir/containers/registries.conf.d/00-docker-hub.conf"
    # DOCKER_HOST for the whole graphical session (terminals, IDEs,
    # lazydocker, Podman Desktop) so docker clients find the Podman socket.
    mkdir -p "$cfgdir/environment.d"
    printf 'DOCKER_HOST=unix://%s\n' "$sock" > "$cfgdir/environment.d/podman.conf"
  fi

  # Docker's API served by the user's Podman, socket-activated (no daemon).
  run systemctl --user enable --now podman.socket

  echo "    Log out and back in so DOCKER_HOST reaches every app."
  echo "    In this shell now: export DOCKER_HOST=unix://$sock"
  echo "    Check: docker run --rm hello-world; podman info | grep rootless"
}

# ----------------------------------------------------------------- ghostty --
# Same settings as programs.ghostty in home/default.nix. Written as a managed
# block at the END of ~/.config/ghostty/config so it overrides Omarchy's
# defaults (JetBrainsMono, block cursor) without touching them.
setup_ghostty() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
  local cfg="$dir/config" theme_src="$repo/dotfiles/ghostty/themes/CanadianShield"
  local begin="# >>> nixconfig (scripts/omarchy-install.sh) >>>"
  local end="# <<< nixconfig <<<"

  [ -f "$theme_src" ] || { echo "missing $theme_src" >&2; exit 1; }
  say "Ghostty: theme and settings"

  run mkdir -p "$dir/themes"
  run install -m644 "$theme_src" "$dir/themes/CanadianShield"

  if [ $dry -eq 1 ]; then
    echo "+ back up $cfg, replace managed block, comment out Omarchy theme include"
    return
  fi

  touch "$cfg"
  cp -n "$cfg" "$cfg.pre-nixconfig" 2>/dev/null || true   # one-time backup

  # Drop any previous managed block.
  sed -i "\|^$begin\$|,\|^$end\$|d" "$cfg"
  sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$cfg"   # trailing blank lines

  # Ghostty processes `config-file` includes after the main file, so Omarchy's
  # dynamic theme (explicit colors) would win over `theme =`. Disable it.
  if [ $keep_omarchy_theme -eq 0 ]; then
    sed -i -E 's|^(config-file = \?.*omarchy/current/theme/ghostty\.conf.*)$|# \1  # disabled by nixconfig; remove "# " to re-enable|' "$cfg"
  fi

  cat >> "$cfg" <<EOF

$begin
theme = CanadianShield
# font-family is a list; the empty value clears Omarchy's JetBrainsMono first.
font-family = ""
font-family = Hack Nerd Font
quit-after-last-window-closed = false
cursor-style = underline
cursor-style-blink = true
# Shell integration otherwise forces a bar cursor at the prompt.
# (ssh-env kept from Omarchy's own setting; all options must be passed together.)
shell-integration-features = no-cursor,ssh-env
$end
EOF
  echo "    wrote $cfg (original saved as $cfg.pre-nixconfig)"
  echo "    Reload Ghostty (ctrl+shift+,) or open a new window."
}

# -------------------------------------------------------------------- main --
[ $do_podman -eq 1 ]   && setup_podman
[ $do_pkgs -eq 1 ]    && install_packages
[ $do_ghostty -eq 1 ] && setup_ghostty
say "Done"
