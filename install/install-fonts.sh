#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

require_command curl
require_command unzip
require_command fc-cache
require_command find

FONT_DIR="$HOME/.local/share/fonts"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
mkdir -p "$FONT_DIR"

install_if_missing() {
  local display_name="$1"
  local archive_url="$2"
  local archive_path="$3"
  local extract_dir="$4"
  local find_expr="$5"

  if fc-list | grep -qi "$display_name"; then
    log "$display_name already installed, skipping"
    return
  fi

  log "Installing $display_name"
  curl -fsSL "$archive_url" -o "$archive_path"
  unzip -qo "$archive_path" -d "$extract_dir"
  find "$extract_dir" -type f \( $find_expr \) -exec cp {} "$FONT_DIR/" \;
}

install_if_missing \
  "Monaspace Neon" \
  "https://github.com/githubnext/monaspace/releases/download/v1.101/monaspace-v1.101.zip" \
  "$TEMP_DIR/monaspace.zip" \
  "$TEMP_DIR/monaspace" \
  '-name *.otf -o -name *.ttf'

install_if_missing \
  "JetBrains Mono" \
  "https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip" \
  "$TEMP_DIR/jetbrainsmono.zip" \
  "$TEMP_DIR/jetbrainsmono" \
  '-name *.ttf'

install_if_missing \
  "MesloLGS Nerd Font" \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip" \
  "$TEMP_DIR/meslo.zip" \
  "$TEMP_DIR/meslo" \
  '-name *.ttf'

log "Refreshing font cache"
fc-cache -fv "$FONT_DIR" >/dev/null 2>&1

log "Font install complete"
