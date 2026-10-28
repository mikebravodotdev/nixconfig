# home/default.nix
# home-manager configuration, shared by macOS (via nix-darwin) and Linux
# (standalone). Platform-specific bits are gated on pkgs.stdenv.

{ pkgs, nixvim, username, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  imports = [
    nixvim.homeModules.nixvim
    ./neovim.nix
    ./packages.nix
    ./shell.nix
    ./linux.nix
  ];

  home.username = username;
  home.homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";
  # Do not bump this to track your actual home-manager version — it pins
  # the format of state home-manager itself manages between releases.
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  home.sessionPath = [ "$HOME/.local/bin" ];

  # On macOS, Ghostty itself is installed via the Homebrew cask (see
  # ../darwin/homebrew.nix) and the font via the "font-hack-nerd-font" cask;
  # home-manager only manages its config (~/.config/ghostty/config).
  # On Linux both come from nixpkgs (fonts in ./linux.nix).
  programs.ghostty = {
    enable = true;
    package = if isDarwin then null else pkgs.ghostty;
    settings = {
      theme = "CanadianShield";
      font-family = "Hack Nerd Font";
      quit-after-last-window-closed = false;
    };
    # home-manager's default systemd unit uses Type=notify-reload, and every
    # `home-manager switch` that touches this config fires its
    # X-Reload-Triggers, sending Ghostty SIGUSR2. Ghostty installs its
    # SIGUSR2 handler late (after it's already told systemd READY=1), so the
    # reload races and systemd kills the service instead of reloading it:
    # https://github.com/ghostty-org/ghostty/issues/14398 (fixed upstream in
    # PR #14399, merged 2026-09-25, but not in any tagged release yet — the
    # nixpkgs build is still v1.3.1, from before the fix). Revisit once
    # nixpkgs picks up a release with that fix.
    systemd.enable = false;
  };

  # Custom Ghostty theme, installed to ~/.config/ghostty/themes/.
  xdg.configFile."ghostty/themes/CanadianShield".source = ../dotfiles/ghostty/themes/CanadianShield;
}
