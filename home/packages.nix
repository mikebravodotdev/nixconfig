# home/packages.nix
# CLI packages for both platforms. Installed per-user via home-manager
# (on macOS they land in /etc/profiles/per-user/<user>/bin).

{ pkgs, lib, cliamp, ... }:

{
  home.packages = [
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.go
    pkgs.rustc
    pkgs.jdk
    pkgs.cargo
    pkgs.fish
    pkgs.nodejs
    pkgs.dotnet-sdk
    pkgs.starship
    pkgs.eza
    pkgs.powershell

    pkgs.nano
    pkgs.python3
    pkgs.ruby
    pkgs.sqlite
    pkgs.lua

    # For the Omarchy-ported bash config (../dotfiles/bashrc.sh)
    pkgs.zoxide
    pkgs.fzf
    pkgs.bat
    pkgs.mise
    pkgs.gum
    pkgs.tmux

    # cliamp terminal music player (flake input) + optional runtime deps
    cliamp.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.ffmpeg
    pkgs.yt-dlp
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    # GNU userland over macOS's BSD tools (Linux already has these)
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.mas
  ];
  # nvim, vi and vim all come from programs.nixvim (./neovim.nix) — adding
  # pkgs.neovim/pkgs.vim here would collide with its wrappers.
}
