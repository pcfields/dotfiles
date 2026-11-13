#!/usr/bin/env bash
# Links the shared agent config (agents/.agents) into harnesses that don't read
# ~/.agents on their own. Stow already puts the package at ~/.agents.
#
# - Claude Code: one symlink per skill into ~/.claude/skills. Per-skill, not a
#   directory link, because the app keeps managed entries beside ours
#   (~/.claude/skills/synced).
# - Codex: ~/.codex/AGENTS.md -> the shared AGENTS.md.
#
# Not needed: Codex and VS Code read ~/.agents/skills directly, and OpenCode
# scans ~/.agents/skills and ~/.claude/skills (linking it too only produces
# duplicate-skill warnings). OpenCode and Claude instructions are wired in
# their own config (opencode.json `instructions`, CLAUDE.md `@` import).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

SHARED_DIR="$ROOT_DIR/agents/.agents"
SHARED_SKILLS="$SHARED_DIR/skills"
SHARED_INSTRUCTIONS="$SHARED_DIR/AGENTS.md"

SKILL_TARGETS=(
  "$HOME/.claude/skills"
)
INSTRUCTION_TARGETS=(
  "$HOME/.codex/AGENTS.md"
)

[[ -d "$SHARED_SKILLS" ]] || { error "Missing $SHARED_SKILLS"; exit 1; }
require_file "$SHARED_INSTRUCTIONS"

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
  local dest
  dest="$target/$(basename "$skill")"

  if [[ -e "$dest" && ! -L "$dest" ]]; then
    warn "Skipping $dest (exists and is not a symlink)"
    return
  fi
  ln -sfn "$skill" "$dest"
}

# Replaces an empty file or a symlink; refuses to overwrite real content.
link_instructions() {
  local dest="$1"

  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" && -s "$dest" ]]; then
    warn "Skipping $dest (has content and is not a symlink)"
    return
  fi
  ln -sfn "$SHARED_INSTRUCTIONS" "$dest"
}

for target in "${SKILL_TARGETS[@]}"; do
  log "Linking shared skills into $target"
  prepare_target "$target"
  for skill in "$SHARED_SKILLS"/*/; do
    link_skill "${skill%/}" "$target"
  done
done

for dest in "${INSTRUCTION_TARGETS[@]}"; do
  log "Linking shared instructions to $dest"
  link_instructions "$dest"
done

log "Agent links done"
