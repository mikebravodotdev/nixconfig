# home.nix
# home-manager configuration for mikebravo.

{ nixvim, ... }:

{
  imports = [
    nixvim.homeModules.nixvim
    ./neovim.nix
  ];

  home.username = "mikebravo";
  home.homeDirectory = "/Users/mikebravo";
  # Do not bump this to track your actual home-manager version — it pins
  # the format of state home-manager itself manages between releases.
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # Ghostty itself is installed via the Homebrew cask (see homebrew.nix);
  # home-manager only manages its config (~/.config/ghostty/config).
  # The font comes from the "font-hack-nerd-font" cask.
  programs.ghostty = {
    enable = true;
    package = null;
    settings = {
      background = "000000";
      foreground = "FFDA03";
      font-family = "Hack Nerd Font";
    };
  };
}
