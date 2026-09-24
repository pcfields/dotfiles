# Claude Code Strategy

A global-only Claude Code configuration for a senior software engineer
working both solo and inside a professional team, tuned for production
quality and well-tested code. It lives entirely in `claude/.claude/`
(stowed to `~/.claude/`), so no per-project `.claude/` folder is required
and it applies unmodified in every repo, including team repos this can't
add config files to. A project's own `CLAUDE.md` layers on top.

## 1. Principles

1. **Deterministic beats prose.** If a setting or hook can enforce a rule,
   it goes in `settings.json`, not `CLAUDE.md`. Prose instructions compete
   with harness defaults and the model's own judgment; settings don't.
2. **`CLAUDE.md` holds only what is relevant in every session.** Occasional
   procedures (committing, TDD) live in skills, which load only when used.
3. **The sandbox is the safety boundary.** Hooks and deny rules are defense
   in depth. They must parse their input correctly, but nothing relies on
   them alone.
4. **Subagents are for context isolation and parallelism, not for a cheaper
   model.** A cold-start subagent re-reads everything it needs, so handing a
   one-line edit to a Haiku agent costs more than doing it inline. The
   built-in `Explore` and `general-purpose` agents cover the cases where
   isolation actually pays.
5. **Every file earns its place.**

## 2. Architecture

```text
claude/.claude/
├── settings.json                    # model, attribution, sandbox, permissions, hook wiring
├── CLAUDE.md                        # global instructions, loaded every session
├── hooks/
│   ├── protect-secrets.sh           # PreToolUse(Read|Edit|Write): blocks secret-shaped paths
│   ├── block-catastrophic-bash.sh   # PreToolUse(Bash): blocks destructive commands
│   └── test-hooks.sh                # regression fixtures for both hooks
└── skills/
    ├── commit/SKILL.md              # plan + create commits split by concern
    └── tdd/SKILL.md                 # Canon TDD: test list, one test at a time, refactor while green
```

`CLAUDE.md` also routes to skills that ship with Claude Code:
`code-review`, `security-review`, and `simplify`.

On Linux, stow links each child of `claude/.claude/` into the existing
`~/.claude/` directory. On Windows, `install/windows/setup-windows-symlinks.ps1`
links the same paths. Both platforms need `jq` on `PATH` (Home Manager on
Linux, scoop on Windows) because the hooks parse their input with it.

## 3. What's enforced vs. what's guidance

**Enforced by the harness (`settings.json`):**

- `model: opusplan`: Opus in plan mode, Sonnet once a plan is approved. The
  model switch at approval breaks the prompt cache, but that is also the
  point to clear context, so it costs little. `showClearContextOnPlanAccept`
  adds a "clear context" choice to the approval dialog so both happen in one
  step. Override per machine with the
  `ANTHROPIC_MODEL` environment variable, set outside the repo (see §6).
- `attribution` set to empty strings, so commits and PRs carry no
  Co-Authored-By trailer or generated-by line.
- `sandbox.enabled`: on Linux, Bash runs under bubblewrap with filesystem
  and network restrictions. This is the real safety boundary.
- `permissions.allow`: read-only commands (`git status/diff/log/show`, `rg`,
  `ls`, `jq`) run without a prompt.
- `permissions.ask`: `git push` and `gh pr create` always prompt, because
  they have external effects.
- `permissions.deny`: the Read tool can't open `.env*`, `*.pem`, `~/.ssh/**`,
  AWS credentials or the gh token file, plus a few disk-destruction command
  patterns.

**Enforced by hooks (defense in depth):**

- `protect-secrets.sh` blocks Read/Edit/Write on secret-shaped paths.
  Reading is the important direction: a secret read into context can leak
  into output, logs or commits. `.env.example`/`.sample`/`.template` are
  allowed.
- `block-catastrophic-bash.sh` blocks recursive force-delete of `/`, `~` or
  `$HOME`, `mkfs`, `dd ... of=/dev/*`, `chmod -R 777 /`, and force-pushes
  (including `+main` refspecs) to `main`/`master`.
- Both parse input with `jq` and **fail closed** on malformed JSON. The
  earlier grep/sed parsing could be bypassed with escaped quotes
  (`bash -c "rm -rf /"`); `test-hooks.sh` pins that case.

**Guidance (`CLAUDE.md`, prompt-level):** communication style, working
discipline, coding principles, one-line commit and TDD rules pointing at
the `commit` and `tdd` skills, and the definition of done.

## 4. Definition of done

- Run the project's tests and any linter/type-checker before calling a task
  complete. Red tests never mean "done."
- New logic and bug fixes go through the `tdd` skill's procedure (§5) when
  the project has a test suite.
- Non-trivial changes get `/code-review low` on the diff before handing
  back. Low effort keeps the gate cheap enough to run every time.

## 5. Test-driven development

Canon TDD (Kent Beck,
[newsletter.kentbeck.com/p/canon-tdd](https://newsletter.kentbeck.com/p/canon-tdd))
is the default technique for new logic and bug fixes, when the project has
a test suite — not a mandate for docs, pure config, or mechanical renames.
The `tdd` skill holds the full procedure so it isn't loaded into every
session: build a test list of behavior variants, convert one item into a
runnable test at a time, make it pass for real (faking the implementation
is fine as a first step — a later test forces a general solution via
triangulation; faking the assertion itself never is), and refactor only
while green. Bug fixes always start with a failing regression test.

## 6. Commits

The `commit` skill holds the full procedure so it isn't loaded into every
session: it proposes a split by concern, **waits for confirmation**, stages
partial files with `git apply --cached` on a hunk patch (never by editing
the working tree back to an intermediate state), and verifies each staged
diff before committing. It never pushes or rewrites history unless asked.

## 7. Cost

- `CLAUDE.md` is short on purpose: every line is billed on every turn.
- Skills load only when used.
- Reasoning effort is a session control (`/effort`), not a prose rule.
- No custom subagents: see principle 4.
- Choose the model at the start of a session. Switching mid-session throws
  away the prompt cache, so the next turn re-reads everything at full price.
- Accounts differ: work (Windows) is an enterprise plan billed per token under
  a cost limit; personal (Linux) is a Pro subscription limited by a usage
  allowance. `opusplan` suits both. To override on one machine only:
  - Windows: `$env:ANTHROPIC_MODEL = "sonnet"` in `powershell/local-private.ps1`
    (untracked).
  - Linux: `set -Ux ANTHROPIC_MODEL sonnet` (stored in the gitignored
    `fish_variables`).

  Confirm the model in effect with `/status`; enterprise managed settings can
  override both.

## 8. Solo vs. team

Nothing here forks behavior by context. A project's own `CLAUDE.md` adds
team rules (PR templates, code owners, stricter review) on top, and the
sandbox, permissions, hooks and definition of done apply regardless of
whose repo it is.

## 9. Verifying changes

```bash
bash claude/.claude/hooks/test-hooks.sh     # hook regression fixtures
jq . claude/.claude/settings.json           # settings are valid JSON
ls -l ~/.claude/                            # CLAUDE.md, settings.json, hooks, skills/commit are symlinks
```

After changing a setting through `/config` or `/model`, check that
`~/.claude/settings.json` is still a symlink. Claude Code writes that file,
and a tool that replaces it instead of writing through the link would
silently fork the live config from the repo.
