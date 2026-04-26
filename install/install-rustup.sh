#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

require_command curl

if command -v rustup >/dev/null 2>&1; then
  log "Rustup already installed at $(command -v rustup)"
  rustup --version
  exit 0
fi

log "Installing Rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

if ! command -v rustup >/dev/null 2>&1; then
  error "Rustup not found after install"
  exit 1
fi

log "Installed Rustup"
rustup --version

echo
echo "Rustup is installed. To add rust-toolchain to a project:"
echo "  rustup toolchain install stable"
echo "To use a specific version:"
echo "  rustup install 1.80.0"