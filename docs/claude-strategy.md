# Claude Code Strategy

A global-only Claude Code configuration for a senior software engineer
working both solo and inside a professional team, tuned for production
quality and well-tested code first, with cost held down by routing simple
work to cheap models and reserving capable ones for what actually needs
them. This lives entirely in `claude/.claude/` (stowed to `~/.claude/`) —
no per-project `.claude/` folder is required, so it applies unmodified in
every repo, including team repos this can't add config files to. A
project's own `CLAUDE.md`, if it has one, layers on top rather than
replacing any of this.

## 1. Architecture

```text
claude/.claude/
├── settings.json                    # default model, permission deny-list, hook wiring
├── CLAUDE.md                        # global instructions, loaded every session
├── agents/
│   ├── docs.md                      # Haiku — README/comments/changelog only
│   ├── small-edits.md               # Haiku — isolated single-file mechanical edits
│   ├── test-writer.md               # Haiku — generate tests, escalates on hard cases
│   └── deep-review.md               # Opus — hard architecture/root-cause/security review
├── hooks/
│   ├── protect-secrets.sh           # PreToolUse(Edit|Write) — blocks secret-shaped paths
│   └── block-catastrophic-bash.sh   # PreToolUse(Bash) — blocks destructive commands
└── skills/
    ├── bug-debugging/SKILL.md       # reproduce → hypothesize → isolate → fix → verify
    ├── commit-message/SKILL.md      # Haiku, forked, explicit-invoke only
    └── explain-code/SKILL.md        # structured explanation for a human reader
```

`CLAUDE.md` also routes to skills that live outside this package but ship
with Claude Code: `code-review`, `security-review`, and `simplify`.

## 2. What's Automatic vs Manual

**Automatic — fires without being asked, every session:**

- `protect-secrets.sh` runs before every `Edit`/`Write` and blocks paths
  that look like secrets (`.env*`, `.pem`, `id_rsa*`/`id_ed25519*`,
  `*credentials*`, `.ssh/*`, `.pfx`, `.p12`).
- `block-catastrophic-bash.sh` runs before every `Bash` call and blocks
  recursive-force-delete of `/`/`~`, disk-level ops (`mkfs`, `dd ... of=/dev/*`),
  `chmod -R 777 /`, and force-pushes to `main`/`master`.
- `settings.json`'s `permissions.deny` list blocks a handful of exact
  catastrophic patterns at the permission layer itself, as a second
  independent check on top of the hook (belt-and-suspenders, not a
  replacement for it).
- `CLAUDE.md` (communication style, coding principles, commit conventions,
  delegation map, definition-of-done, cost-efficiency rules) loads into
  every session automatically — these are prompt-level defaults, not
  tool-enforced, but they apply without you invoking anything.
- `bug-debugging` and `explain-code` are model-invocable: Claude can reach
  for them on its own when a task matches, without you naming them.
- Sonnet is the default model for the main loop unless you switch it.

**Manual — requires a deliberate invocation:**

- `commit-message` sets `disable-model-invocation: true`, so it only runs
  when you explicitly ask for a commit message — it will never fire on its
  own.
- The four subagents (`docs`, `small-edits`, `test-writer`, `deep-review`)
  aren't triggered by a hook or a file pattern — Claude decides per task,
  guided by the delegation map, whether to hand work off to one. You can
  also ask for one by name.
- `code-review` / `security-review` / `simplify` — run on request, or
  automatically as part of the definition-of-done gate on non-trivial
  changes (see §5) — not on every edit.
- Any `/model` switch, including escalating to Opus outside `deep-review`,
  is entirely manual.

## 3. Model / Cost Tiering

| Tier | Model | Used for |
|---|---|---|
| Default loop | Sonnet | Everything not delegated — the large majority of real work. |
| Cheap, mechanical | Haiku (`docs`, `small-edits`, `test-writer`) | README/comment edits, single-file mechanical changes, test generation for straightforward code. |
| Cheap, isolated | Haiku (`commit-message`, `context: fork`) | Drafting a commit message from the staged diff, in a forked context so it doesn't add tokens to the main session. |
| Expensive, rare | Opus (`deep-review`) | Hard architecture tradeoffs, root-causing that's resisted normal debugging, security-sensitive design review. Explicitly told to hand back rather than pad the work if the task turns out routine. |

**No automatic task-based routing** — Claude Code doesn't inspect a task
and pick a model by difficulty on its own. The routing that exists is
either pinned to a subagent/skill (automatic *within that scope*, per §2)
or a manual `/model` switch. What keeps this cost-effective without a
router is the **escalation-on-uncertainty pattern** baked into every cheap
agent: `small-edits` stops and reports back if a task turns out to touch
more than one file's logic; `test-writer` hands back if the code under
test has non-trivial branching, concurrency, or business-critical logic
instead of guessing at coverage; `deep-review` itself says so and hands
back if a task turns out to be routine once it's in there. Cheap models
handle the bulk of the volume; anything a cheap model would have to guess
on gets escalated rather than quietly under-served — which is what keeps
the cost savings from coming at the expense of the "well-tested" priority.

## 4. Safety Hooks

Two independent layers, deliberately narrow to avoid false positives (the
hook comments call this out explicitly — a safety net, not a substitute
for normal permission prompts):

- **`protect-secrets.sh`** — blocks `Edit`/`Write` to anything that looks
  like a credential file. Doesn't block reads; edit manually if a match is
  a false positive.
- **`block-catastrophic-bash.sh`** — blocks destructive filesystem/disk
  commands and force-pushes to `main`/`master` specifically (feature
  branches aren't restricted).
- **`permissions.deny`** in `settings.json` — a short exact-match list
  covering the same class of catastrophic commands, as a second check that
  doesn't depend on the hook's regex being right.

## 5. Definition of Done (Quality Gate)

Stated directly in `CLAUDE.md`, since testing and quality are the primary
goal, not an afterthought:

- Before a task is called complete: run the project's test suite and any
  linter/type-checker; fix failures or report them explicitly. Red tests
  never mean "done."
- For non-trivial changes (new logic, bug fixes — not docs or mechanical
  edits): run `code-review` at medium effort on the diff before handing
  back, noting what was addressed vs. deliberately left.

This, plus `test-writer`'s escalation rule (§3) and the `bug-debugging`
skill's reproduce → hypothesize → isolate → smallest-fix → verify
discipline, is what makes "well-tested" an enforced step rather than a
value statement.

## 6. Delegation & Skills Map

From `CLAUDE.md` — "prefer the cheapest tool that can correctly do the
job":

| Need | Use |
|---|---|
| Find files, search code, map a codebase | built-in `Explore` agent |
| Multi-step research/execution that isn't code search | built-in `general-purpose` agent |
| Single-file mechanical edit | `small-edits` (Haiku) |
| README / comments / changelog only | `docs` (Haiku) |
| Generate tests for existing code | `test-writer` (Haiku, escalates when needed) |
| Hard architecture/root-cause/security review | `deep-review` (Opus, use sparingly) |
| Draft a commit message from staged changes | `commit-message` skill |
| Investigate a bug | `bug-debugging` skill |
| Explain unfamiliar code to a human | `explain-code` skill |
| Review a diff for correctness/cleanup | `code-review` / `simplify` skills |
| Check a diff for security issues | `security-review` skill |

## 7. Cost-Reduction Techniques

**Prompt-side:**

- `CLAUDE.md` is kept short by design ("keep this file short since it
  loads into every session's context") — every line is billed every turn.
- Skill content only loads into context when the skill actually fires, not
  kept permanently resident.
- Reasoning effort defaults to low/medium; high effort is reserved for
  genuinely hard architectural or correctness questions.

**Session-side:**

- Prefer `Grep`/`Glob` over reading whole files — read only the slice
  needed.
- Batch independent reads/searches in parallel instead of sequentially.
- Use `/clear` between unrelated tasks rather than letting context grow
  across topics.

**Model-side:**

- Delegate search, exploration, and mechanical edits per §6 instead of
  doing them in the main loop on Sonnet.
- Reach for `deep-review` (Opus) only when a task has genuinely earned it
  — cheap agents and the default loop escalate rather than silently
  under-serving hard cases, but nothing routes to Opus automatically.

## 8. Solo vs. Team

Nothing in this configuration forks behavior by context — the same
`~/.claude/` applies whether the repo is a personal project or a work
repo this account can't add files to. What differs by repo is layered on
top, not baked in here: a project's own `CLAUDE.md` can add team-specific
rules (PR templates, code owners, stricter review requirements) without
touching this global config, and the definition-of-done gate (§5) and
safety hooks (§4) apply either way regardless of whose repo it is.

## 9. Summary

One default model (Sonnet), a cheap Haiku tier for mechanical/isolated
work (three subagents plus a forked commit-message skill), one deliberately
rare Opus tier for hard problems, and an escalation-on-uncertainty pattern
that keeps the cheap tier from silently under-serving anything nontrivial.
Two hooks plus a permission deny-list form a narrow, false-positive-averse
safety net. A definition-of-done gate makes "well-tested" a checked step,
not a preference. All of it lives in one global config that works
unmodified whether the repo is solo or shared.
