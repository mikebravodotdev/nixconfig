# home/appimages/default.nix
# Upstream AppImages, pinned by URL + hash in ./sources.json and wrapped with
# nixpkgs' appimageTools so they run on any distro and get desktop entries
# and icons. Bump versions with scripts/update-appimages.sh. Linux-only.

{ pkgs, lib, ... }:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);

  mkAppImage = pname: { version, url, hash }:
    let
      src = pkgs.fetchurl { inherit url hash; };
      contents = pkgs.appimageTools.extract { inherit pname version src; };
    in
    pkgs.appimageTools.wrapType2 {
      inherit pname version src;
      # Install the AppImage's own .desktop file(s), pointed at the wrapper,
      # plus its icons (themed if shipped, else the top-level icon file).
      extraInstallCommands = ''
        for f in ${contents}/*.desktop; do
          d="$out/share/applications/$(basename "$f")"
          install -Dm444 "$f" "$d"
          sed -i -E -e 's|^Exec=[^ ]*|Exec=${pname}|' -e '/^TryExec=/d' "$d"
        done
        if [ -d ${contents}/usr/share/icons ]; then
          mkdir -p $out/share
          cp -r ${contents}/usr/share/icons $out/share/
        else
          for i in ${contents}/*.png ${contents}/*.svg; do
            [ -e "$i" ] && install -Dm444 "$i" "$out/share/pixmaps/$(basename "$i")"
          done
        fi
      '';
    };
in
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home.packages = lib.mapAttrsToList mkAppImage sources;
  };
}
