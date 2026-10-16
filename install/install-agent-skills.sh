#!/usr/bin/env bash
# Links each shared skill (agents/.config/agents/skills/*) into every agent
# harness's skills directory, one symlink per skill. Per-skill links, not a
# directory link, because harnesses keep app-managed entries beside ours
# (~/.claude/skills/synced, ~/.codex/skills/.system).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

SHARED_SKILLS="$ROOT_DIR/agents/.config/agents/skills"

# Codex reads ~/.agents/skills natively.
TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.agents/skills"
)

[[ -d "$SHARED_SKILLS" ]] || { error "Missing $SHARED_SKILLS"; exit 1; }

# A target dir that is itself a symlink (the old stow-folded layout) would
# make us write into the repo; replace it with a real directory first.
prepare_target() {
  local target="$1"
  if [[ -L "$target" ]]; then
    warn "Replacing directory symlink $target with a real directory"
    rm "$target"
  fi
  mkdir -p "$target"
}

link_skill() {
  local skill="$1" target="$2"
  local name dest
  name="$(basename "$skill")"
  dest="$target/$name"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    warn "Skipping $dest (exists and is not a symlink)"
    return
  fi
  ln -sfn "$skill" "$dest"
}

for target in "${TARGETS[@]}"; do
  log "Linking shared skills into $target"
  prepare_target "$target"
  for skill in "$SHARED_SKILLS"/*/; do
    link_skill "${skill%/}" "$target"
  done
done

log "Agent skills linked"
