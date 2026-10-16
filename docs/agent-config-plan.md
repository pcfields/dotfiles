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
    checks/                    # pass/fail scripts, one contract (below)
      lib/                     # only when two or more checks share code
    tests/                     # tests for checks, plus link/frontmatter validation
```

Where other things live:

| Kind | Home |
|---|---|
| Pass/fail check (blocking, lint, static analysis, secret scan) | `checks/` |
| Helper owned by one skill | `skills/<name>/scripts/` |
| Wiring for one harness (Claude `settings.json` entries, OpenCode plugin) | that harness's package |
| Installing or linking | `install/` |
| Tests and package validation | `tests/` |
| Command wanted on `PATH` | `bin/`, created only when first needed |

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

### Checks and deterministic logic

Checks are the shared core: no harness knowledge, tested with plain values.

Contract (provisional):

- Exit 0 passes; exit 2 blocks, with the reason on stderr.
- Input is JSON on stdin. For now the shape is Claude's `PreToolUse` shape
  (`tool_input.command`, `tool_input.file_path`) because the existing checks read
  it. Revisit when the second adapter (OpenCode, step 5) lands: either adapters
  translate to this shape or the shape becomes neutral.
- Names are `<verb>-<subject>.sh`.

Adapters:

- Claude: `settings.json` hook entries calling the checks.
- OpenCode: one JS/TS plugin (`tool.execute.before`) that shells out to the
  checks and throws on exit 2.
- Codex: depends on what the installed version supports. Verify first;
  otherwise rely on its sandbox and approval policy.
- Harness-neutral enforcement (git hooks, `mise` tasks, CI) is preferred wherever
  it can replace an agent hook; agent hooks add feedback during the work.

Guardrail layers, earliest to latest: instructions, pre-action block,
post-action feedback (lint/format results fed back to the agent), completion
gate (tests pass), git hooks, CI. Consider protecting lint, test and CI config
from agent edits.

Later option: if checks multiply or share parsing, promote them to one CLI
(`agent-check <name>`) with the same contract. Not now.

### Not shared

`settings.json`, `opencode.json` and `config.toml` stay per harness. Generating
them from one source would be speculative; revisit if duplication hurts.

## Steps

Each step is its own commit and independently revertable.

1. [x] **Tidy:** reconcile the diverged `tdd` skill copies (no behavior change).
2. [x] Create the `agents/` package; move skills in; re-point Claude and OpenCode links.
3. [ ] Move hook scripts to `agents/.agents/checks/` and `test-hooks.sh` to `agents/.agents/tests/`; update `settings.json` paths and the Windows link entry; run tests.
4. [ ] Unify the instructions file; wire Codex `AGENTS.md`.
5. [ ] Verify Codex/OpenCode skill and hook paths for installed versions; add the OpenCode plugin adapter, then Codex's if supported.
6. [ ] Add the link/frontmatter check script.
7. [ ] Update the Windows symlink script, `docs/strategy.md` and `docs/install.md`.

## Decisions

- Home: `~/.agents/` (decided: Codex and VS Code read `~/.agents/skills` natively; stow mirrors the path as `agents/.agents/`).
- Open: exact Codex and OpenCode skill/hook paths (step 5 verifies).

## Risks

- Stow conflicts when replacing existing real directories or links: back up and
  check `stow -n` output before restowing.
- Harness-specific frontmatter in skills may not be ignored by every tool.
- Hook protocols differ; the adapter, not the core, absorbs the difference.
