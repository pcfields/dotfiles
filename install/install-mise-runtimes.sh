#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

require_command mise

log "Installing mise runtimes from config"
mise install --yes

log "Installed mise tools"
mise list
