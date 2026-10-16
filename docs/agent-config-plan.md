# Shared agent config plan

Goal: one place to edit instructions, skills and deterministic logic, used by
Claude Code, OpenCode, Codex and any later harness.

## Problem

- Claude and OpenCode each keep their own copy of instructions and skills, and
  the copies drift (`tdd/SKILL.md` differs between them).
- Codex has an empty `~/.codex/AGENTS.md`.
- Hook logic lives under `claude/.claude/hooks/`, so only Claude can use it.

## Design

A neutral source of truth plus thin per-harness adapters. Shared parts are data
and calculations; each harness gets only a small action layer that wires them in.

### Layout (new stow package `agents/`)

```
agents/
  .agents/
    AGENTS.md                  # global instructions
    skills/<name>/SKILL.md     # shared skills; scripts/ inside a skill for its own helpers
```

Stowed to `~/.agents/` (read natively by Codex and VS Code). Add `agents` to `STOW_PACKAGES` and mirror the
links in `install/windows/setup-windows-symlinks.ps1`.

### Instructions

| Harness  | Wiring |
|----------|--------|
| Claude   | `~/.claude/CLAUDE.md` holds `@~/.agents/AGENTS.md` plus Claude-only lines |
| OpenCode | `~/.config/opencode/AGENTS.md` symlinks to the shared file |
| Codex    | `~/.codex/AGENTS.md` symlinks to the shared file |

The shared file stays free of tool names.

### Skills

`SKILL.md` is the common format. Keep skills once under `agents/.agents/skills/`
and link that directory to each harness's skills path. Keep bodies tool-neutral;
use a small override file for a harness-specific tweak rather than forking.

### Hooks and checks (deferred)

Decision: the Claude hooks stay in `claude/.claude/hooks/` for now. Sharing
guardrails across harnesses is postponed until it earns its complexity.

Design notes for when we return to it:

- A `checks/` folder in the `agents` package, one contract: exit 0 passes, exit 2
  blocks with the reason on stderr. Names `<verb>-<subject>.sh`.
- Checks know nothing about any harness. They take a small neutral JSON shape
  (`phase`, `action`, `command` or `path`). One normalizer per harness converts
  Claude's, OpenCode's or Codex's event into it, so a new harness adds one file.
- Policy (for example secret path patterns) lives in data files with a local
  override, not hardcoded in scripts.
- OpenCode adapter: a JS/TS plugin on `tool.execute.before`. Codex: verify what
  its installed version supports.
- Prefer harness-neutral layers where possible: git hooks, `mise` tasks, CI.
- Guardrail layers, earliest to latest: instructions, pre-action block,
  post-action feedback, completion gate, git hooks, CI. Consider protecting lint,
  test and CI config from agent edits.
- If checks multiply, promote them to one CLI (`agent-check <name>`) with the
  same contract.

### Not shared

`settings.json`, `opencode.json` and `config.toml` stay per harness. Generating
them from one source would be speculative; revisit if duplication hurts.

## Steps

Each step is its own commit and independently revertable.

1. [x] **Tidy:** reconcile the diverged `tdd` skill copies (no behavior change).
2. [x] Create the `agents/` package; move skills in; re-point Claude and OpenCode links.
3. [ ] Unify the instructions file; wire OpenCode and Codex `AGENTS.md`.
4. [ ] Add the link/frontmatter check script for the shared package.
5. [ ] Update the Windows symlink script (`~/.agents`, drop the stale Claude skills entry), `docs/strategy.md` and `docs/install.md`.
6. [ ] Deferred: shared hooks and checks (see above).

## Decisions

- Home: `~/.agents/` (decided: Codex and VS Code read `~/.agents/skills` natively; stow mirrors the path as `agents/.agents/`).
- Open: exact Codex and OpenCode skill/hook paths (step 5 verifies).

## Risks

- Stow conflicts when replacing existing real directories or links: back up and
  check `stow -n` output before restowing.
- Harness-specific frontmatter in skills may not be ignored by every tool.
- Hook protocols differ; the adapter, not the core, absorbs the difference.
