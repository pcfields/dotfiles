#!/usr/bin/env bash
# ── Install Nix + Home Manager ───────────────────────────────────────
# Installs Nix (if needed), enables flakes, and runs home-manager switch.
# This assumes dotfiles have already been stowed (so ~/.config/nix/ exists).
set -euo pipefail

NIX_CONFIG_DIR="$HOME/.config/nix"
FLAKE_DIR="$NIX_CONFIG_DIR"

# ── Install Nix ──────────────────────────────────────────────────────
echo "==> Checking for Nix..."
if ! command -v nix &>/dev/null; then
  echo "==> Installing Nix (multi-user daemon mode)..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  echo ""
  echo "!! Nix installed. You MUST restart your shell (or reboot) and re-run this script."
  echo "!! Run:  exec bash  (then re-run this script)"
  exit 0
fi

# ── Enable flakes ────────────────────────────────────────────────────
echo "==> Ensuring flakes are enabled..."
mkdir -p "$NIX_CONFIG_DIR"
if ! grep -q "experimental-features" "$NIX_CONFIG_DIR/nix.conf" 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >> "$NIX_CONFIG_DIR/nix.conf"
fi

# ── Verify flake.nix exists ─────────────────────────────────────────
if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
  echo "ERROR: $FLAKE_DIR/flake.nix not found."
  echo "Make sure you ran stow-dotfiles.sh first to symlink nix config."
  exit 1
fi

# ── Run Home Manager ────────────────────────────────────────────────
echo "==> Running Home Manager switch..."
nix run home-manager/master -- switch --flake "$FLAKE_DIR"

# ── Set up Fish as default shell ─────────────────────────────────────
FISH_PATH="$(which fish 2>/dev/null || echo "$HOME/.nix-profile/bin/fish")"
if [[ -x "$FISH_PATH" ]]; then
  echo "==> Adding Fish to /etc/shells (requires sudo)..."
  if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
  fi

  echo "==> Setting Fish as default shell..."
  chsh -s "$FISH_PATH"
  echo "  -> Fish set as default. Log out and back in for it to take effect."
else
  echo "WARNING: Fish not found. Skipping shell change."
fi

echo ""
echo "==> Nix + Home Manager setup complete!"
echo ""
echo "To update packages in the future:"
echo "  cd ~/.config/nix && nix flake update && home-manager switch --flake ."
echo ""
echo "To add/remove packages:"
echo "  Edit ~/.config/nix/home.nix, then run: home-manager switch --flake ~/.config/nix"
