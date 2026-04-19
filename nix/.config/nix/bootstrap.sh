#!/usr/bin/env bash
# ── Pop!_OS Nix + Home Manager Bootstrap ──────────────────────────────
# Run this script once on a fresh system to set everything up.
# After that, use: home-manager switch --flake ~/.config/nix
set -euo pipefail

echo "==> Checking for Nix..."
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix (multi-user)..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo "==> Nix installed. Please restart your shell and re-run this script."
  exit 0
fi

echo "==> Enabling flakes..."
mkdir -p ~/.config/nix
grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null || \
  echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

echo "==> Bootstrapping Home Manager..."
nix run home-manager/master -- switch --flake ~/.config/nix

echo "==> Adding Fish to /etc/shells (requires sudo)..."
FISH_PATH="$(which fish 2>/dev/null || echo "$HOME/.nix-profile/bin/fish")"
if ! grep -q "$FISH_PATH" /etc/shells; then
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

echo "==> Setting Fish as default shell..."
chsh -s "$FISH_PATH"

echo ""
echo "Done! Log out and back in, or run: exec fish"
echo ""
echo "To update packages in the future:"
echo "  cd ~/.config/nix && nix flake update && home-manager switch --flake ."
echo ""
echo "To add/remove packages:"
echo "  Edit ~/.config/nix/home.nix, then run: home-manager switch --flake ~/.config/nix"
