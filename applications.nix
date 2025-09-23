# applications.nix

{ pkgs, ... }:

{
  # List all packages you want to install globally.
  environment.systemPackages = [
    pkgs.lmstudio
    pkgs.firefox
    pkgs.firefox-devedition
    pkgs.google-chrome
    pkgs.zed-editor
    pkgs.vscode
    pkgs.audacity
    pkgs.iterm2
    pkgs.wezterm
    pkgs.lapce
    pkgs.librewolf
    pkgs.logseq
    pkgs.podman-desktop
    pkgs.element-desktop
    pkgs.slack
    pkgs.telegram-desktop
    pkgs.utm
    # pkgs.standardnotes
  ];
}
