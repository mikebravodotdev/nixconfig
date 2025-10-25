# packages.nix

{ pkgs, ... }:

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
    pkgs.cargo
    pkgs.fish
    pkgs.nodejs
    pkgs.starship
    pkgs.eza
  ];
}
