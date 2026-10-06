# packages.nix

{ pkgs, cliamp, ... }:

{
  # List all packages you want to install globally.
  environment.systemPackages = [
    pkgs.vim
    pkgs.neovim
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.go
    pkgs.rustc
    pkgs.jdk
    pkgs.cargo
    pkgs.fish
    pkgs.nodejs
    pkgs.starship
    pkgs.eza
    pkgs.powershell

    # Moved from Homebrew so they're declared instead of dangling installs
    pkgs.coreutils
    pkgs.gnugrep
    pkgs.nano
    pkgs.python3
    pkgs.ruby
    pkgs.sqlite
    pkgs.mas
    pkgs.lua

    # For the Omarchy-ported bash config (bashrc.local.sh)
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
  ];
}
