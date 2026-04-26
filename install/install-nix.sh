#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

NIX_CONFIG_DIR="$HOME/.config/nix"
FLAKE_DIR="$NIX_CONFIG_DIR"

require_command curl

if ! command -v nix >/dev/null 2>&1; then
  log "Installing Nix in multi-user daemon mode"
  sh <(curl -L https://nixos.org/nix/install) --daemon
  warn "Restart your shell or reboot, then re-run ./install.sh nix"
  exit 0
fi

require_file "$FLAKE_DIR/flake.nix"
require_file "$NIX_CONFIG_DIR/nix.conf"

log "Running Home Manager switch"
nix run home-manager/master -- switch --flake "$FLAKE_DIR"

FISH_PATH="$(command -v fish 2>/dev/null || echo "$HOME/.nix-profile/bin/fish")"
if [[ -x "$FISH_PATH" ]]; then
  log "Ensuring Fish is in /etc/shells"
  if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  log "Setting Fish as default shell"
  chsh -s "$FISH_PATH"
  warn "Log out and back in for the shell change to take effect"
else
  warn "Fish not found, skipping default shell change"
fi

log "Nix install complete"
