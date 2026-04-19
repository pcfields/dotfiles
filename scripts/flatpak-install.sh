#!/usr/bin/env bash
# ── Install Flatpak Packages ────────────────────────────────────────
# Adds Flathub and installs apps from flatpak-packages.txt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$DOTFILES_DIR/packages/flatpak-packages.txt"

if [[ ! -f "$PACKAGES_FILE" ]]; then
  echo "ERROR: $PACKAGES_FILE not found"
  exit 1
fi

# ── Ensure flatpak is installed ──────────────────────────────────────
if ! command -v flatpak &>/dev/null; then
  echo "==> Installing flatpak..."
  sudo apt install -y flatpak
fi

# ── Add Flathub ──────────────────────────────────────────────────────
echo "==> Ensuring Flathub remote is added..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# ── Install packages ────────────────────────────────────────────────
echo "==> Reading package list from $PACKAGES_FILE..."
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"
  [[ -z "$line" ]] && continue

  echo "  -> Installing $line..."
  flatpak install -y flathub "$line" || echo "  !! Failed to install $line (may already be installed)"
done < "$PACKAGES_FILE"

echo "==> Flatpak installation complete!"
