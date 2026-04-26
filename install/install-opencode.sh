#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

require_command curl
require_command bash

INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.local/bin}"

if command -v opencode >/dev/null 2>&1; then
  log "OpenCode already installed at $(command -v opencode)"
  opencode --version
  exit 0
fi

mkdir -p "$INSTALL_DIR"
log "Installing OpenCode to $INSTALL_DIR"
OPENCODE_INSTALL_DIR="$INSTALL_DIR" curl -fsSL https://opencode.ai/install | bash

export PATH="$INSTALL_DIR:$PATH"

if ! command -v opencode >/dev/null 2>&1; then
  error "OpenCode not found after install. Check $INSTALL_DIR"
  exit 1
fi

log "Installed OpenCode"
opencode --version

echo
echo "Provider setup: opencode -> /connect"
echo "Config expected at: ~/.config/opencode (linked via stow)"
