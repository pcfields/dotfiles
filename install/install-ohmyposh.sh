#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

require_command curl

INSTALL_DIR="${HOME}/.local/bin"

if command -v oh-my-posh >/dev/null 2>&1; then
  log "Oh My Posh already installed at $(command -v oh-my-posh)"
  oh-my-posh version
  exit 0
fi

log "Installing Oh My Posh to $INSTALL_DIR"
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$INSTALL_DIR"

if [[ ! -x "$INSTALL_DIR/oh-my-posh" ]]; then
  error "Oh My Posh not found at $INSTALL_DIR/oh-my-posh"
  exit 1
fi

log "Installed Oh My Posh"
"$INSTALL_DIR/oh-my-posh" version

echo
echo "Oh My Posh config expected at: ~/.config/ohmyposh/ (linked via stow)"