# home/shell.nix
# Bash + prompt + readline, for both platforms. Replaces the old nix-darwin
# /etc/bash.local, /etc/starship.toml and /etc/inputrc.omarchy files, which
# had no equivalent on a non-NixOS Linux box.

{ pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;

    # Runs before the non-interactive early return in ~/.bashrc.
    # Keep what the distro's stock ~/.bashrc did, now that home-manager owns it:
    # source the system bashrc (Fedora: /etc/bashrc, Debian: /etc/bash.bashrc,
    # which carries completion and the prompt defaults; Nix's own PATH setup
    # comes from /etc/profile.d/*) and put ~/.local/bin and ~/bin on PATH.
    bashrcExtra = lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      if [ -f /etc/bashrc ]; then
        . /etc/bashrc
      elif [ -f /etc/bash.bashrc ]; then
        . /etc/bash.bashrc
      fi

      if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
        PATH="$HOME/.local/bin:$HOME/bin:$PATH"
      fi
      export PATH
    '';

    initExtra = builtins.readFile ../dotfiles/bashrc.sh;
  };

  # Starship reads ~/.config/starship.toml by default.
  xdg.configFile."starship.toml".source = ../dotfiles/starship.toml;

  # Loaded on top of the system inputrc with `bind -f` in bashrc.sh.
  xdg.configFile."readline/omarchy.inputrc".source = ../dotfiles/inputrc;
}
