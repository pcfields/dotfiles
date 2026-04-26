#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

log "Installing Fish shell via official PPA"

require_command sudo
require_command apt-get

if ! command -v add-apt-repository >/dev/null 2>&1; then
  log "Installing software-properties-common"
  sudo apt-get update
  sudo apt-get install -y software-properties-common
fi

if ! grep -Rqs "fish-shell/release-4" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null; then
  log "Adding fish-shell PPA"
  sudo add-apt-repository -y ppa:fish-shell/release-4
else
  log "Fish PPA already configured"
fi

log "Updating package lists"
sudo apt-get update

if dpkg -s fish >/dev/null 2>&1; then
  log "Fish is already installed"
else
  log "Installing fish"
  sudo apt-get install -y fish
fi

FISH_PATH="$(command -v fish || true)"
if [[ -n "$FISH_PATH" ]]; then
  if ! grep -qx "$FISH_PATH" /etc/shells; then
    log "Adding fish to /etc/shells"
    echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
  fi

  log "Setting fish as default shell"
  chsh -s "$FISH_PATH"
fi
