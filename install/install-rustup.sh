#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

require_command curl

# Components the Neovim setup depends on. rust-analyzer comes from rustup rather
# than Nix so it stays version-locked to the toolchain that compiles the code;
# a mismatched pair produces confusing false diagnostics.
RUST_COMPONENTS=(rust-analyzer clippy rustfmt)

install_components() {
  local installed
  installed="$(rustup component list --installed)"

  for component in "${RUST_COMPONENTS[@]}"; do
    if grep -q "^${component}" <<<"$installed"; then
      log "Component already installed: $component"
    else
      log "Adding component: $component"
      rustup component add "$component"
    fi
  done
}

if command -v rustup >/dev/null 2>&1; then
  log "Rustup already installed at $(command -v rustup)"
  rustup --version
  install_components
  exit 0
fi

log "Installing Rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

if [[ -f "$HOME/.cargo/env" ]]; then
  source "$HOME/.cargo/env"
fi

if ! command -v rustup >/dev/null 2>&1; then
  error "Rustup not found after install"
  exit 1
fi

log "Installed Rustup"
rustup --version

install_components

echo
echo "Rustup is installed. To add rust-toolchain to a project:"
echo "  rustup toolchain install stable"
echo "To use a specific version:"
echo "  rustup install 1.80.0"