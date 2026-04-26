#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

NIX_CONFIG_DIR="$HOME/.config/nix"
FLAKE_DIR="$NIX_CONFIG_DIR"

require_command curl

if ! command -v nix >/dev/null 2>&1; then
  log "Installing Nix (single-user mode -- no daemon)"
  log "Single-user mode is sufficient for desktop use with Home Manager"
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
  warn "Nix installed. Restart your shell, then re-run ./install.sh nix"
  exit 1
fi

require_file "$FLAKE_DIR/flake.nix"
require_file "$NIX_CONFIG_DIR/nix.conf"

log "Running Home Manager switch"
  nix run home-manager/master -- switch --flake "$FLAKE_DIR"

  # Fish shell is managed via apt (see install-fish.sh) to ensure it's available
  # early in the boot process. Nix only handles Fish integration for tools like fzf.

  log "Nix install complete"
