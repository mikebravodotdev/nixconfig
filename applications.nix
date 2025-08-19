# applications.nix

{ pkgs, ... }:

{
  # List all packages you want to install globally.
  environment.systemPackages = [
    pkgs.firefox
    pkgs.firefox-devedition
    pkgs.google-chrome
    pkgs.zed-editor
    pkgs.vscode
    pkgs.audacity
    pkgs.obs-studio
    pkgs.ghostty
    pkgs.iterm2
    pkgs.wezterm
    pkgs.jami
    pkgs.lapce
    pkgs.librewolf
    pkgs.libreoffice-fresh
    pkgs.logseq
    pkgs.podman-desktop
    pkgs.proton-pass
    pkgs.element-desktop
    pkgs.session-desktop
    pkgs.signal-desktop
    pkgs.slack
    pkgs.telegram-desktop
    pkgs.utm
  ];
}
