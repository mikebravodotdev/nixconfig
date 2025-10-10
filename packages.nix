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
    pkgs.dotnet-sdk
    pkgs.go
    # pkgs.dart
    pkgs.rustc
    pkgs.cargo
    pkgs.fish
    pkgs.nodejs
  ];
}
