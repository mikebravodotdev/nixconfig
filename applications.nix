# applications.nix

{ pkgs, ... }:

{
  # This file is intentionally left empty.
  # All GUI applications have been moved to homebrew.nix for better stability on macOS.
  # You can remove this file and its import from flake.nix.
  environment.systemPackages = [ ];
}