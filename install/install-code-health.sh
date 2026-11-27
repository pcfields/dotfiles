#!/usr/bin/env bash
# Installs the code-health binary into ~/.local/bin from a release of the
# private code-health repo, at the version in packages/code-health-version.txt.
# Needs GH_TOKEN set to a fine-grained token for gh, and CODE_HEALTH_REPO set
# to <owner>/<name>: see docs/secrets.md.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

version="$(read_package_file "$ROOT_DIR/packages/code-health-version.txt")"
bin="$HOME/.local/bin/code-health"

require_command gh
if [[ -z "${CODE_HEALTH_REPO:-}" ]]; then
  error "CODE_HEALTH_REPO is not set: see docs/secrets.md"
  exit 1
fi

# The Python tool was a uv tool with its shim at the same path.
if command -v uv >/dev/null 2>&1 && uv tool list 2>/dev/null | grep -q '^code-health '; then
  log "Removing the uv-installed Python code-health"
  uv tool uninstall code-health
fi

if [[ "$("$bin" --version 2>/dev/null)" == "code-health ${version#v}" ]]; then
  log "code-health $version is already installed at $bin"
  exit 0
fi

log "Downloading code-health $version"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh release download "$version" --repo "$CODE_HEALTH_REPO" --pattern code-health --dir "$tmp"
mkdir -p "$(dirname "$bin")"
rm -f "$bin"
install -m 755 "$tmp/code-health" "$bin"

log "Installed $("$bin" --version) at $bin"
