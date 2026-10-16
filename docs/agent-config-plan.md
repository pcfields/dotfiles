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
  .config/agents/
    AGENTS.md              # global instructions
    skills/<name>/SKILL.md # shared skills
    bin/                   # deterministic scripts (JSON on stdin, exit 2 blocks)
    tests/                 # fast tests for bin/ and a link/frontmatter check
```

Stowed to `~/.config/agents/`. Add `agents` to `STOW_PACKAGES` and mirror the
links in `install/windows/setup-windows-symlinks.ps1`.

### Instructions

| Harness  | Wiring |
|----------|--------|
| Claude   | `~/.claude/CLAUDE.md` holds `@~/.config/agents/AGENTS.md` plus Claude-only lines |
| OpenCode | `~/.config/opencode/AGENTS.md` symlinks to the shared file |
| Codex    | `~/.codex/AGENTS.md` symlinks to the shared file |

The shared file stays free of tool names.

### Skills

`SKILL.md` is the common format. Keep skills once under `agents/.config/agents/skills/`
and link that directory to each harness's skills path. Keep bodies tool-neutral;
use a small override file for a harness-specific tweak rather than forking.

### Hooks and deterministic logic

- Core: scripts in `agents/bin/`, no harness knowledge, tested with plain values.
- Claude adapter: `settings.json` hook entries calling the scripts.
- OpenCode adapter: one JS/TS plugin (`tool.execute.before`) that shells out to
  the scripts and throws on exit 2.
- Codex adapter: depends on what the installed version supports. Verify first;
  otherwise rely on its sandbox and approval policy.
- Harness-neutral enforcement (git hooks, `mise` tasks) is preferred wherever it
  can replace an agent hook.

### Not shared

`settings.json`, `opencode.json` and `config.toml` stay per harness. Generating
them from one source would be speculative; revisit if duplication hurts.

## Steps

Each step is its own commit and independently revertable.

1. [ ] **Tidy:** reconcile the diverged `tdd` skill copies (no behavior change).
2. [ ] Create the `agents/` package; move skills in; re-point Claude and OpenCode links.
3. [ ] Move hook scripts and `test-hooks.sh` to `agents/bin/` and `agents/tests/`; update `settings.json` paths; run tests.
4. [ ] Unify the instructions file; wire Codex `AGENTS.md`.
5. [ ] Verify Codex/OpenCode skill and hook paths for installed versions; add the OpenCode plugin adapter, then Codex's if supported.
6. [ ] Add the link/frontmatter check script.
7. [ ] Update the Windows symlink script, `docs/strategy.md` and `docs/install.md`.

## Decisions

- Home: `~/.config/agents/` (default; `~/.agents/` is the alternative).
- Open: exact Codex and OpenCode skill/hook paths (step 5 verifies).

## Risks

- Stow conflicts when replacing existing real directories or links: back up and
  check `stow -n` output before restowing.
- Harness-specific frontmatter in skills may not be ignored by every tool.
- Hook protocols differ; the adapter, not the core, absorbs the difference.
