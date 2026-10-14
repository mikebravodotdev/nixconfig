#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#curl nixpkgs#jq --command bash
# Bump the AppImages pinned in home/appimages/sources.json to their latest
# upstream releases. Usage: scripts/update-appimages.sh [name ...]
# (no names = all). Review the diff, then `home-manager switch`.
set -euo pipefail
cd "$(dirname "$0")/.."
json=home/appimages/sources.json

gh_latest() { # <owner/repo> <asset regex>
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    jq -r --arg re "$2" '[.assets[].browser_download_url | select(test($re))][0]'
}

latest_url() {
  case $1 in
    librewolf)
      curl -fsSL "https://codeberg.org/api/v1/repos/librewolf/bsys6/releases?limit=1" |
        jq -r '[.[0].assets[].browser_download_url | select(test("x86_64-appimage\\.AppImage$"))][0]' ;;
    ungoogled-chromium) gh_latest ungoogled-software/ungoogled-chromium-portablelinux 'x86_64\.AppImage$' ;;
    jitsi-meet)         gh_latest jitsi/jitsi-meet-electron 'x86_64\.AppImage$' ;;
    session-desktop)    gh_latest session-foundation/session-desktop 'x86_64.*\.AppImage$' ;;
    audacity)           gh_latest audacity/audacity 'x86_64\.AppImage$' ;;
    logseq)             gh_latest logseq/logseq 'x86_64.*\.AppImage$' ;;
    lmstudio)           curl -fsSL -o /dev/null -w '%{url_effective}' https://lmstudio.ai/download/latest/linux/x64 ;;
    *) echo "unknown AppImage: $1" >&2; return 1 ;;
  esac
}

names=("$@")
[ ${#names[@]} -gt 0 ] || mapfile -t names < <(jq -r 'keys_unsorted[]' "$json")

for name in "${names[@]}"; do
  url=$(latest_url "$name")
  [[ $url == https://* ]] || { echo "$name: couldn't resolve a download URL" >&2; exit 1; }
  if [ "$url" = "$(jq -r --arg n "$name" '.[$n].url // ""' "$json")" ]; then
    echo "$name: up to date"
    continue
  fi
  # Every source puts the release version in the directory just above the
  # file (e.g. .../download/v2026.8.0/foo.AppImage); drop any tag prefix.
  tag=${url%/*}; tag=${tag##*/}
  version=${tag#"${tag%%[0-9]*}"}
  echo "$name: -> $version"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  updated=$(jq --arg n "$name" --arg v "$version" --arg u "$url" --arg h "$hash" \
    '.[$n] = { version: $v, url: $u, hash: $h }' "$json")
  printf '%s\n' "$updated" > "$json"
done
