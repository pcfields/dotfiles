#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

STOW_PACKAGES=(
  fish
  git
  mise
  nix
  nvim
  ohmyposh
  opencode
  wezterm
)

require_command stow
log "Stowing dotfiles from $ROOT_DIR"

for pkg in "${STOW_PACKAGES[@]}"; do
  pkg_dir="$ROOT_DIR/$pkg"

  if [[ ! -d "$pkg_dir" ]]; then
    warn "Skipping $pkg (directory not found)"
    continue
  fi

  log "Stowing $pkg"
  stow -d "$ROOT_DIR" -t "$HOME" --restow "$pkg"
done

log "Stow complete"
