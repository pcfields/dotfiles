#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

PACKAGES_FILE="$(packages_file flatpak-packages.txt)"

if ! command -v flatpak >/dev/null 2>&1; then
  log "Installing Flatpak"
  sudo apt install -y flatpak
fi

log "Ensuring Flathub remote exists"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

log "Installing Flatpak packages"
while IFS= read -r package; do
  log "Installing $package"
  flatpak install -y flathub "$package"
done < <(read_package_file "$PACKAGES_FILE")

log "Flatpak install complete"
