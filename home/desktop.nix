# home/desktop.nix
# The Hyprland desktop on Linux (Debian 13 on bigGuy): Hyprland, the Quickshell
# shell, terminals, fonts, and the helper scripts. Linux-only; on macOS this
# module defines an option and nothing else.
#
# Hyprland, Quickshell, hypridle/hyprlock, the portals and their Qt modules are
# installed from apt (see ../scripts/install-linux-desktop-packages.sh) because
# they need system integration (greetd/uwsm session, PAM, GPU drivers) that
# home-manager can't provide on a non-NixOS distro. This module owns their
# *configuration*. See ../docs/linux-desktop.md.

{ config, pkgs, lib, omarchy, ... }:

let
  cfg = config.desktop;

  # Link a path under dotfiles/linux/ into $HOME *by reference* to the checkout,
  # not as a copy in the Nix store. The files in ~/.config are then the repo's
  # own files: edit a QML file, restart Quickshell (or `hyprctl reload`), and
  # `git diff` shows exactly what changed. No `home-manager switch` per tweak.
  live = path: config.lib.file.mkOutOfStoreSymlink "${cfg.repoPath}/dotfiles/linux/${path}";

  # Theme palettes, previews and wallpapers for the theme switcher, taken from
  # Omarchy (MIT) and pinned by the flake lock instead of vendored in git
  # (~75 MB of images). Only what `theme-apply` reads is kept: each theme's
  # colors.toml, preview.png, and still wallpapers (not the video intros, the
  # editor themes, or Omarchy's own logo image).
  themes = pkgs.runCommand "quickshell-themes" { } ''
    mkdir -p "$out"
    for t in ${omarchy}/themes/*/; do
      name=$(basename "$t")
      mkdir -p "$out/$name/backgrounds"
      cp "$t/colors.toml" "$out/$name/"
      if [ -f "$t/preview.png" ]; then cp "$t/preview.png" "$out/$name/"; fi
      if [ -f "$t/light.mode" ]; then cp "$t/light.mode" "$out/$name/"; fi
      for f in "$t"/backgrounds/*; do
        if [ ! -f "$f" ]; then continue; fi
        case "$(basename "$f")" in
          omarchy.webp) continue ;;
          *.webp|*.png|*.jpg|*.jpeg) cp "$f" "$out/$name/backgrounds/" ;;
        esac
      done
    done
    cp ${omarchy}/LICENSE "$out/LICENSE-omarchy"
  '';
in
{
  options.desktop.repoPath = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/Code/nixconfig";
    description = ''
      Where this repository is checked out. Config files under dotfiles/linux
      are symlinked to it, so it has to exist before the first switch.
    '';
  };

  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    xdg.configFile = {
      # Hyprland (Lua config) and its idle/lock helpers.
      "hypr/hyprland.lua".source = live "hypr/hyprland.lua";
      "hypr/conf".source = live "hypr/conf";
      "hypr/hypridle.conf".source = live "hypr/hypridle.conf";
      "hypr/hyprlock.conf".source = live "hypr/hyprlock.conf";

      # The Quickshell shell. Linked per item rather than as one directory
      # because `themes` below comes from the Nix store, not the checkout.
      "quickshell/shell.qml".source = live "quickshell/shell.qml";
      "quickshell/common".source = live "quickshell/common";
      "quickshell/components".source = live "quickshell/components";
      "quickshell/panels".source = live "quickshell/panels";
      "quickshell/services".source = live "quickshell/services";
      "quickshell/themes".source = themes;

      # Terminals. theme-apply writes the colors next to these
      # (kitty/current-theme.conf, foot/current-theme.ini), so only the files
      # themselves are managed, never their directories.
      "kitty/kitty.conf".source = live "kitty/kitty.conf";
      # foot's `include=` needs an absolute path, hence generated here.
      "foot/foot.ini".text = ''
        include=${config.xdg.configHome}/foot/current-theme.ini
        # foot config. Colors come from theme-apply (current-theme.ini).
        [main]
        font=Hack Nerd Font Mono:size=13
      '';

      # Hack Nerd Font as the default monospace font for every app.
      "fontconfig/fonts.conf".source = ../dotfiles/linux/fontconfig/fonts.conf;
    };

    # Helper scripts: theme-apply (palette -> shell, Hyprland, kitty, foot,
    # hyprlock), lock-screen (Quickshell lock, hyprlock fallback), and
    # hypr-screenshot. ~/.local/bin is on the session PATH (./default.nix).
    home.file = {
      ".local/bin/theme-apply".source = live "bin/theme-apply";
      ".local/bin/lock-screen".source = live "bin/lock-screen";
      ".local/bin/hypr-screenshot".source = live "bin/hypr-screenshot";
    };

    home.packages = [
      # The icon glyphs the shell draws. Hack Nerd Font itself comes from
      # ./linux.nix; this is the fallback that covers every other font.
      pkgs.nerd-fonts.symbols-only
    ];
  };
}
