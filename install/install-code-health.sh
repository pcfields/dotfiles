#!/usr/bin/env bash
# Installs the code-health CLI (agents/.agents/tools/code-health) with uv, as
# an editable tool, and downloads its tree-sitter grammars so a first run
# works offline. Re-run with --force after the tool's dependencies change.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

TOOL_DIR="$ROOT_DIR/agents/.agents/tools/code-health"

if ! command -v uv >/dev/null 2>&1; then
  error "uv not found: run ./install.sh nix (or home-manager switch), then open a new shell"
  exit 1
fi
require_file "$TOOL_DIR/pyproject.toml"

log "Installing code-health from $TOOL_DIR"
uv tool install --editable --force "$TOOL_DIR"

export PATH="$HOME/.local/bin:$PATH"
if ! command -v code-health >/dev/null 2>&1; then
  error "code-health not found after install. Check that ~/.local/bin is on PATH"
  exit 1
fi

log "Downloading tree-sitter grammars"
code-health grammars

log "Installed code-health at $(command -v code-health)"
