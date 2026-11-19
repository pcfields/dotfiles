# Plan: code-health tool

A handoff plan. An agent with no prior context should be able to do this work
from this file and the repo alone. The decisions here are agreed with the
user; ask before changing one. Steps are ordered: do them one at a time,
commit each, and tick them off here as they land.

> This repo is public. Never write client names, client repo names, client
> code, paths from client repos or personal details into it: not in this
> plan, fixtures, tests or commit messages.

## Why

Agentic coding is fast, but agents write complex code they then can't
safely change. Research presented by Adam Tornhill (CodeScene, GOTO 2026,
"AI-Friendly Code") reports:

- AI breaks code about 60% more often at a Code Health of 9 than at 10.
  Code that agents can work in safely starts around 9.5; aim for 10.
- Unaided, a frontier agent fixes about 20% of code smells. With a Code
  Health tool telling it the score and naming each smell, it fixes 90-100%.
- The mechanism is a loop: the agent writes code, a tool scores it and lists
  what's wrong, the agent refactors, and the tool re-scores until nothing new
  is wrong.

CodeScene sells this as the CodeHealth MCP server. We build our own: free, on
any machine, in any project, and open to any agent harness.

## Decisions

| Topic | Decision | Why |
|---|---|---|
| Shape | One CLI, `code-health`, harness-neutral. Each harness gets a thin adapter (Claude Code first, as a Stop hook). An MCP server can come later, wrapping `--json`. | One scorer, so the file and repo reports never disagree. Hooks fire every time; an MCP tool only fires when the agent chooses to call it. |
| Skills | Keep the `repo-health` skill name. It calls `code-health repo` instead of `repo-health.sh`. No new skill: the edit loop is a hook. | The skill name is the question people ask ("how healthy is this repo"). The consistency belongs in the CLI, where everything is under `code-health`. |
| Language | Python 3.12+, parsing with tree-sitter (`tree-sitter-language-pack`), packaged with `uv` and installed with `uv tool install --editable`. | tree-sitter gives one real parser for every language, including bash and PowerShell, which lizard can't read. Python is quick to change while the rules are being calibrated. uv pins its own Python, which avoids mise shim breaks (lizard and cloc have both hit "not provided by the active python/node"). Port to Rust later only if speed or distribution needs it. |
| Languages | C#, TypeScript, TSX, JavaScript, JSX, bash, PowerShell, Lua, Rust, SQL (T-SQL). | What the user writes. VB.NET is out: it's listed as "not scored". |
| Score | 1.0-10.0 per file. Bands: green ≥ 9, yellow ≥ 4, red < 4. | Matches CodeScene's scale. The bands are from memory of CodeScene, not a published source. |
| When the safeguard fails | A changed file gains a **new** finding, an existing finding gets **worse**, or a new ignore comment is added. Findings that were already there and not made worse are reported but don't fail. | Comparing findings is precise and gives the agent a to-do list. A fixed bar (say 9.5) would either let small regressions through in green files or block every edit to a red legacy file. Any drop in score comes from a new or worse finding, so this catches it. |
| Approving a failure for now | Only the user can approve, with `code-health accept`. It needs an interactive terminal and a typed `yes`, and Claude's settings also deny it to the agent. The agent is told to ask the user and shows the exact command. | The agent must never be able to approve its own regression. Requiring a terminal works the same in every harness, because agents' shell calls have no terminal. |
| Durable exceptions | A comment above the function, `code-health: ignore <Smell> -- <reason>`, with the reason required. Adding one counts as a finding until the user accepts it. | It sits with the code and shows up in review. |
| Per-repo config | `.code-health.toml` at the repo root: excluded paths, plus rule weights and thresholds per path pattern. | Like CodeScene's `.codescene/code-health-rules.json`. |
| Project history | Local to each project, in `<repo>/.code-health/`, added to `.git/info/exclude`. Never committed. | Project repos are shared with clients and teams. |
| Global history | Generic records only, in a **separate private repo** (this repo is public). The location comes from `CODE_HEALTH_HISTORY_DIR`. When that isn't set, the tool skips writing and says so once; it never fails because of it. | The records are for estimating client costs ("1,000 lines from 4 to 10 took 20k tokens"). Even with names stripped, that is commercially sensitive. |

## Read first

- `agents/.agents/AGENTS.md`: the user's rules (TDD, functional core with a
  thin shell, testing, commits, definition of done).
- `agents/.agents/skills/repo-health/`: `SKILL.md`, `GOTCHAS.md`,
  `scripts/repo-health.sh` (what the port must keep),
  `scripts/build-report.py` and `assets/report.html`.
- `agents/.agents/skills/refactor/`: `SKILL.md` (measures before and after,
  keeps a playbook) and `refactorings.md` (problem → named refactoring; reuse
  it for fix hints).
- `agents/.agents/checks/run-project-check.sh` and
  `claude/.claude/hooks/run-check-on-stop.sh`: the pattern to copy. The logic
  is harness-neutral, and a thin Claude adapter fails open and lets the agent
  stop on its second try.
- `claude/.claude/settings.json` and `claude/.claude/hooks/test-hooks.sh`.
- `.agents/check`: this repo's fast checks. Add the tool's tests to it.
- `CLAUDE.md`: how configs are linked (Stow on Linux, symlinks on Windows)
  and which package manager owns what.

## Smells (v1)

Every finding has a smell name, a function (or `<file>`), a start line, the
measured value and the limit. The limits below are **starting values to
calibrate**, not CodeScene's (theirs aren't published).

| Smell | Detected when | Fix hint (from `refactorings.md`) |
|---|---|---|
| Complex Method | Cyclomatic complexity ≥ 10. Count 1, plus each `if`/`else if`, loop, `case`, `catch`, ternary, `&&`, `\|\|` and `??`. | Extract Function; Decompose Conditional |
| Deep Nested Complexity | Control structures nested ≥ 4 deep inside one function. | Replace Nested Conditional with Guard Clauses; Extract Function |
| Bumpy Road | ≥ 2 separate top-level blocks in the function body that each reach nesting ≥ 2. | Extract Function per bump |
| Complex Conditional | One condition (`if`/`while`/ternary) with ≥ 2 boolean operators. | Decompose Conditional; Explaining variable |
| Large Method | ≥ 70 lines of code (blank and comment lines not counted). | Extract Function; Split Phase |
| Excess Function Arguments | ≥ 5 parameters. Constructors: ≥ 8, because C# dependency injection legitimately takes many. | Introduce Parameter Object |
| Large File | ≥ 1,000 lines of code. | Split the module by responsibility |
| Correlated Subquery in SELECT (SQL only) | A subquery in the SELECT list that references the outer query. | Rewrite as a JOIN (also a rule in AGENTS.md) |

Language notes:
- Top-level script code in bash, PowerShell, Lua and SQL batches is measured
  as a pseudo-function named `<script>`.
- SQL procedures, functions and triggers count as functions. T-SQL
  `IF`/`WHILE`/`CASE WHEN`/`BEGIN TRY` count as branches and nesting.
- In the user's repos, SQL procedures live inside migration scripts, so
  migrations are **not** excluded by default.
- Test files (`**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/*Tests/**`)
  give Large Method half weight by default.
- Default exclusions: `*.min.js`, `*.min.css`, `vendor/`, `node_modules/`,
  `dist/`, `build/`, `bin/`, `obj/`, `*.Designer.cs`, `*.g.cs`,
  `*.generated.*` and lockfiles.
- A file with tree-sitter ERROR nodes is "not scored" (with a reason), never
  10.

Later, not in v1: Code Duplication (DRY), Brain Method/Brain Class, Low
Cohesion, Primitive Obsession, and test assertion-block smells.

## Score

Start with this formula and tune its constants against the calibration
fixtures:

- Each finding's penalty = rule weight × base × (1 + how far over the limit,
  as a fraction of the limit), capped at 3 × base. Base is 1.0 for most
  smells, 1.5 for Deep Nested Complexity and 1.25 for Complex Method.
- File score = 1 + 9 × e^(−k × total penalty), rounded to one decimal. Start
  with k ≈ 0.12, so a single just-over-the-limit finding gives about 9.0.
- No findings = 10.0.
- Every record carries `scorer_version`. Bump it whenever rules, limits or
  the formula change, and never compare scores across versions.

**Calibration fixtures.** Write these fresh in TypeScript; don't copy the
talk's demo code. A `processPayment(data)` that validates data, amount,
currency and card, converts currency, adds a fee and returns a result:
- **v1:** each check nests inside the previous one, 8 levels deep, with about
  14 branches and magic numbers. Must score ≤ 4.5 and report Complex Method
  and Deep Nested Complexity.
- **v2:** guard clauses, with card validation and currency conversion
  extracted. Must score between v1 and 10 and still report something in
  `processPayment`.
- **v3:** validation fully extracted, named constants, small functions. Must
  score 10.0 with no findings.

## CLI

```
code-health score <file>...                 # one line per file: score, band
code-health review <file>...                # score + findings + fix hints
code-health safeguard [--base <ref>]        # changes vs HEAD (or vs merge-base with <ref>)
code-health accept <file> --smell <name> [--function <name>] --reason <text>   # user only
code-health repo [--since ...] [--top N] [--data] [<path>]   # replaces repo-health.sh
code-health episode start|end ...           # refactoring cost records (see History)
```

- Every command takes `--json`.
- Exit codes: 0 pass, 2 safeguard failed, 1 the tool itself failed.
  Adapters turn 1 into "skip with a warning" (fail open).
- Files are read from the working tree. The baseline comes from
  `git show <ref>:<path>`.
- Changed files: tracked changes (staged and unstaged) plus untracked files
  that aren't ignored, using rename detection to find each file's baseline.
  New files have an empty baseline, and deleted files are ignored.
- Findings are matched across versions by (smell, function name). A renamed
  function shows up as new findings; that's an accepted limitation.
- Run git with `-c core.quotePath=false -c submodule.recurse=false` (see the
  repo-health GOTCHAS).

Safeguard text output (what the agent reads), modelled on CodeScene's MCP
review card:

```
code-health safeguard: FAIL (3 files checked, 1 got worse)

src/payment.ts  9.1 -> 6.3  worse
  x new       Deep Nested Complexity  processPayment:12  depth 6 (limit 4)
              fix: Replace Nested Conditional with Guard Clauses; Extract Function
  x worse     Complex Method          processPayment:12  14 branches, was 9 (limit 10)
              fix: Extract Function; Decompose Conditional
  ! existing  Large Method            validate:80        92 lines (limit 70)
  ok fixed    Bumpy Road              formatReceipt

Refactor until no "x" lines remain, then run `code-health safeguard` again.
Lower numbers with worse readability is a failure: don't split code into
pieces too small to follow. If a finding has to stay, ask the user. Only
they can run, in a terminal:
  code-health accept src/payment.ts --smell "Deep Nested Complexity" --function processPayment --reason "<why>"
```

## Approvals and suppressions

- `accept` refuses unless stdin is a terminal and the user types `yes` at a
  prompt that shows the finding.
- It appends to `<repo>/.code-health/accepted.jsonl`: file, smell, function,
  a hash of the function's current text, the reason and the date. When the
  function's text changes, the acceptance no longer matches and lapses.
- In Claude's `settings.json`, deny `Bash(code-health accept:*)` and
  `Edit`/`Write` on `**/.code-health/accepted.jsonl`, as a second line of
  defence.
- Ignore comments: `code-health: ignore <Smell> -- <reason>` on the line
  above a function (any comment syntax). An ignore comment without a reason
  is itself a finding. A **new** ignore comment fails the safeguard until it
  is accepted.

## History

**Project (local).** Everything lives under `<repo>/.code-health/`, excluded
through `.git/info/exclude`. This replaces `.repo-health/`.
- `snapshots.jsonl`: one line per `code-health repo` run, with:
  - date, commit, branch, `scorer_version`, files scored and not scored
  - average health, weighted by lines of code
  - hotspot health: average over the top-N hotspots, weighted by commits
  - the worst file and its score
  - a map of every file's score
- `episodes.jsonl`: full refactoring-cost records, including paths.
- `accepted.jsonl`: see above.
- `repo/`: the data tables for the HTML report.

The HTML report gains a trend chart of average health, hotspot health and
the worst file over the snapshots.

**Global (private, generic).** Append to
`$CODE_HEALTH_HISTORY_DIR/episodes.jsonl` with **only** these fields:

```json
{"date": "2026-11-19", "scorer_version": "1", "kind": "safeguard-fix | uplift",
 "language": "csharp", "loc_band": "500-1000", "functions": 34,
 "score_before": 4.2, "score_after": 10.0,
 "findings_before": {"Complex Method": 3}, "findings_after": {},
 "iterations": 3, "duration_s": 840, "tests_passed": true,
 "tokens": {"input": 0, "output": 0, "cache_creation": 0, "cache_read": 0},
 "token_method": "claude-transcript-window | partial | none",
 "model": "claude-opus-5-5", "harness": "claude-code"}
```

No paths, repo names, function names, code or authors. A test asserts that
the record has only these keys.

**Episodes.** An episode is one stretch of refactoring work, from a baseline
to an end.
- **safeguard-fix:** starts when the safeguard first fails in a session and
  ends at the next stop, pass or fail. The Claude adapter opens and closes
  it.
- **uplift:** the `refactor` skill calls `code-health episode start --kind
  uplift <file>` at its step 1 and `episode end` at its step 6.
- Open episodes are kept in `<repo>/.code-health/pending.json`. `episode end`
  records scores. The harness adapter fills in tokens, because only it knows
  the transcript.

**Token counting (Claude Code).** The Stop hook's input JSON includes
`transcript_path`, `session_id`, `cwd` and `stop_hook_active`.
- The transcript is JSONL. Assistant lines have `type: "assistant"`, an ISO
  `timestamp`, `message.model`, `message.id` and `message.usage` with
  `input_tokens`, `output_tokens`, `cache_creation_input_tokens` and
  `cache_read_input_tokens` (seen on 2026-11-19).
- Sum usage over assistant lines whose timestamp falls inside the episode.
- **Count each `message.id` once.** One message can span several lines; check
  this against a real transcript first.
- An episode that spans sessions gets `token_method: "partial"`.
- Put this in `code_health/harness/claude.py` with a sample-transcript
  fixture (synthetic, no real content).

## Claude Code adapter

- `claude/.claude/hooks/code-health-on-stop.sh`: reads the hook's JSON and
  runs `code-health safeguard`.
  - On exit 2, it prints the output to stderr and exits 2, so Claude keeps
    working.
  - When `stop_hook_active` is true, it still runs the safeguard, but only to
    close the episode, and always exits 0.
  - A missing tool or an exit 1 → a warning and exit 0.
  - It records episodes and tokens as above.
- Register it as a second `Stop` hook in `claude/.claude/settings.json`
  (timeout 60), next to `run-check-on-stop.sh`. Add the deny rules from
  "Approvals and suppressions".
- Add cases to `claude/.claude/hooks/test-hooks.sh`.
- Check whether commands the user runs with `!` in Claude Code have a
  terminal. Either way, the guidance tells the user to run `accept` in a
  terminal.
- In `agents/.agents/AGENTS.md` "Definition of done", replace the
  `repo-health.sh <file>` line with "run `code-health safeguard`; fix every
  new or worse finding, or ask the user to accept it".

## Layout

```
agents/.agents/tools/code-health/
  pyproject.toml          # uv project; entry point `code-health`
  src/code_health/
    languages.py          # per-language tree-sitter node types: functions, branches, nesting, boolean ops, params
    measure.py            # calculation: syntax tree -> function and file metrics
    smells.py             # calculation: metrics + rules -> findings
    score.py              # calculation: findings -> score, band
    delta.py              # calculation: before/after findings -> verdict
    config.py             # .code-health.toml + defaults
    ignores.py            # ignore comments, accepted.jsonl matching
    history.py            # action: snapshots, episodes, global records
    repo.py               # port of repo-health.sh: churn, authors, coupling, hotspots
    gitio.py              # action: git calls
    harness/claude.py     # transcript token counting
    cli.py                # thin shell
  tests/
    fixtures/<language>/  # small handwritten samples per smell
```

Keep the logic in pure functions (`measure`, `smells`, `score`, `delta`) and
test them directly with plain values. Test the CLI through real temporary git
repos, not mocks.

## Steps

Each step gets one or more commits (conventional commits, one logical change
each) and leaves `bash .agents/check` green.

1. **Spike the grammars.** Create the uv project. Write a test that parses
   one sample per language (C#, TS, TSX, JS, JSX, bash, PowerShell, Lua,
   Rust, T-SQL) with no ERROR nodes, and record each language's node type
   names. If PowerShell, C# or T-SQL is missing from the language pack or
   parses badly, **stop and report to the user** with the alternatives (a
   separate grammar package, or a token-based fallback for SQL). Checked by
   pytest.
2. **Metrics for TypeScript** (functions, CC, nesting, bumps, conditionals,
   params, LOC). TDD with fixtures. Checked by pytest.
3. **Smells and score for TypeScript**, plus the three calibration fixtures.
   Checked by pytest (v1 ≤ 4.5 < v2 < v3 = 10.0).
4. **`score` and `review`** with text and `--json` output. Add
   `uv run --project agents/.agents/tools/code-health pytest` to
   `.agents/check`. Checked by CLI tests.
5. **`safeguard`** (changes vs HEAD, and `--base`). Checked by tests on
   temporary git repos: unchanged, worse, not worse in a red file, new file,
   rename, deleted.
6. **Claude adapter**, settings entries, `test-hooks.sh` cases and the
   AGENTS.md definition-of-done line. Checked by `test-hooks.sh` and a live
   run in a scratch repo.
7. **Languages, one commit each:** C#, JS/JSX/TSX, bash, PowerShell, Lua,
   Rust, SQL. Each needs fixtures for every smell, plus `<script>` handling
   where it applies. Checked by pytest.
8. **Config, ignore comments and `accept`.** Checked by pytest, with a test
   that `accept` refuses without a terminal.
9. **`code-health repo`:** port churn, author density, coupling
   (`MAX_COMMIT_FILES=50`, `MIN_SHARED_COMMITS=3`) and hotspots, and add
   snapshots and the trend chart.
   - Refactor-first ranking: commits × (10 − score). Keep a plain
     change-frequency table with scores, and a "healthy but busy" section.
   - Update `build-report.py` and `report.html`: colour by score band, add
     the trend chart, read from `.code-health/repo/`.
   - Rewrite `repo-health/SKILL.md` to use `code-health repo`, then delete
     `repo-health.sh`.
   - Update references: the `spec` skill (line about grading files), the
     `refactor` skill (baseline and re-measure use `code-health review`) and
     `docs/install-windows.md`.

   Checked by `bash .agents/check` and a run on this repo.
10. **Episodes, global history and token capture,** with episode start and
    end added to the `refactor` skill. Checked by pytest with a synthetic
    transcript and a key-allowlist test on global records.
11. **Install wiring.**
    - Linux: add `uv` to `nix/.config/nix/home.nix`, and add an install step
      that runs `uv tool install --editable ~/.agents/tools/code-health`,
      following the `STEPS` pattern in `install.sh`.
    - Windows: add `uv` to `packages/scoop-packages.txt`, and a script or
      section in `install/windows/` that runs the same command.
    - Remove `lizard` from `packages/pip-packages.txt` and `home.nix`.
    - Document it in `docs/install.md` and `docs/install-windows.md`.

    Checked by running the Linux step.
12. **Windows check** (on the Windows machine): install, run `safeguard` and
    the hook in a scratch repo, and confirm CRLF files and Windows paths
    work. Report anything Linux-only.

Later: an MCP server wrapping `--json` (tools like `score`, `review`,
`safeguard`), adapters for other harnesses (OpenCode, Codex), duplication and
test smells, Brain Class and Low Cohesion, and calibrating against the
CodeScene trial on about 20 files.

## Risks

- **Grammar gaps** (PowerShell, newer C#, T-SQL). Step 1 tests this first.
  An unparseable file is "not scored", never 10.
- **The score looks authoritative but is uncalibrated.** It carries
  `scorer_version`, and calibrating against CodeScene comes later.
- **The agent games the score** by splitting code into tiny functions. The
  safeguard's message says not to, and the refactor skill already treats that
  as a failure.
- **The Stop hook is slow.** It only parses changed files. Target under 2
  seconds for a typical change, and measure it in step 6.
- **Token counts are noisy:** the window includes other work. That's stated
  in `token_method`, and the numbers are estimates.
- **Client data leaks into this public repo.** Fixtures are synthetic,
  global records are limited to an allowlist of keys, and the history lives
  in a private repo.
- **Windows differences** (paths, CRLF, no `timeout`). Step 12.
