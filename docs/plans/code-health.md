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
| Languages | C#, TypeScript, TSX, JavaScript, JSX, bash, PowerShell, Lua, Rust, Python. SQL is out of v1 (see "Revisit: SQL"). | What the user writes. Python was added after step 1, so the tool can check its own code. VB.NET is out: it's listed as "not scored". SQL was dropped after step 1 found no usable T-SQL grammar. |
| Platforms | Everything works on Linux and Windows: the CLI, tests, adapters and install. Use `pathlib`, handle CRLF, and resolve home and cache dirs per platform. A Linux-only part is a bug, or a named gap with a step that closes it. | The user works on both machines from one tree. |
| Score | 1.0-10.0 per file. Bands: green ≥ 9, yellow ≥ 4, red < 4. | Matches CodeScene's scale. The bands are from memory of CodeScene, not a published source. |
| When the safeguard fails | A changed file gains a **new** finding, an existing finding gets **worse**, or a new ignore comment is added. Findings that were already there and not made worse are reported but don't fail. | Comparing findings is precise and gives the agent a to-do list. A fixed bar (say 9.5) would either let small regressions through in green files or block every edit to a red legacy file. Any drop in score comes from a new or worse finding, so this catches it. |
| Approving a failure for now | Only the user can approve, with `code-health accept`. It needs an interactive terminal and a typed `yes`, and writes to a per-user state folder outside the repo (`$XDG_STATE_HOME`/`~/.local/state` or `%LOCALAPPDATA%`, `code-health/<repo key>/`), which the agent's sandbox can't write. Claude's settings also deny it to the agent. The agent is told to ask the user and shows the exact command. | The agent must never be able to approve its own regression. The terminal check alone isn't airtight (an agent can fake one with `script` or `pty`), so the write location is the real lock on Linux and macOS. Windows has no Claude sandbox: there it rests on the deny rules and the terminal check. |
| What the safeguard compares with | The commit at the start of the agent's turn: a `UserPromptSubmit` hook runs `code-health mark-turn`, and the Stop hook runs `safeguard --since-turn`. Without a mark it falls back to HEAD. The mark is kept in the same state folder. | Comparing with HEAD misses everything the agent commits during its turn. Added in step 8. |
| Durable exceptions | A comment above the function, `code-health: ignore <Smell> -- <reason>`, with the reason required. Adding one counts as a finding until the user accepts it. | It sits with the code and shows up in review. |
| Per-repo config | `.code-health.toml` at the repo root: excluded paths, plus rule weights and thresholds per path pattern. `score` and `review` read the working copy; `safeguard` reads the base commit's copy and notes when the working copy differs. Claude asks before editing it. | Like CodeScene's `.codescene/code-health-rules.json`. Reading the base commit's copy stops an agent loosening a limit and passing in the same turn. |
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

Language notes:
- Top-level script code in bash, PowerShell, Lua and Python is measured as
  a pseudo-function named `<script>`.
- Python: `self` and `cls` don't count toward Excess Function Arguments.
  Comprehension `for` and `if` clauses count as loops and branches.
- Node type names per language are in `src/code_health/languages.py`
  (recorded in step 1). JSX uses the `javascript` grammar.
- PowerShell grammar gaps, pinned in `test_known_parse_gaps`: the
  PowerShell 7 `??` operator and `? :` ternary, a `switch` with several
  clauses on one line, and a braced variable followed by a colon in a
  command argument (`${svc}:tag`, seen in an open-source repo). Files using them are "not scored".
- Test files (`**/*.test.*`, `**/*.spec.*`, `**/tests/**`, `**/*Tests/**`)
  give Large Method half weight by default.
- Callbacks passed to `describe`, `context` or `suite` (scorer version 3)
  and top-level IIFEs, `(function () { … })()` (version 4), skip Large
  Method: they are long because they hold other functions, each measured
  on its own.
- TypeScript grammar gap: `import('…')` used as a type (`typeof import('./x')`,
  `import('./x').T[]`) gives parse errors, so the file is "not scored".
- Default exclusions: `*.min.js`, `*.min.css`, `vendor/`, `node_modules/`,
  `dist/`, `obj/`, `*.Designer.cs`, `*.g.cs`,
  `*.generated.*` and lockfiles.
- A file with tree-sitter ERROR nodes is "not scored" (with a reason), never
  10.

Later, not in v1: Code Duplication (DRY), Brain Method/Brain Class, Low
Cohesion, Primitive Obsession, and test assertion-block smells.

## Score

Start with this formula and tune its constants against the calibration
fixtures:

- Each finding's penalty = rule weight × base × (1 + 2 × how far over the
  limit, as a fraction of the limit), capped at 4 × base. Base is 1.0 for
  most smells, 1.5 for Deep Nested Complexity and 1.25 for Complex Method.
  Tuned in step 3: the starting values (1 × overage, cap 3 × base) scored
  v1 at 5.3. With 2 × and 4 × it scores 4.1, while one finding at its limit
  still scores 9.0, so `k` was left at 0.12. The constants are in
  `score.py`.
- Repeats of one smell in a file (say, ten similar overloads) count at most
  2 × that smell's worst penalty in the file. Added as scorer version 2,
  after an open-source C# repo scored a file of animation-helper overloads
  red (2.4), below a controller with real nesting and branching.
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
- It appends to `accepted.jsonl` in the per-user state folder (see Decisions): file, smell, function,
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
- `claude/.claude/hooks/code-health-turn-start.sh` (`UserPromptSubmit`)
  records the turn's base with `code-health mark-turn --session <id>`; the
  Stop hook passes `--since-turn --session <id>` (added in step 8). Both
  find the command through `code-health-command.sh`.
- Add cases to `claude/.claude/hooks/test-hooks.sh`.
- Check whether commands the user runs with `!` in Claude Code have a
  terminal. Either way, the guidance tells the user to run `accept` in a
  terminal.
- In `agents/.agents/AGENTS.md` "Definition of done", add a line saying
  `code-health safeguard` flags new or worse smells and only the user may
  accept one (done in step 6). Remove the `repo-health.sh <file>` line in
  step 11, once `code-health` is on PATH and scores every language.

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
    ignores.py            # ignore comments
    accept.py             # accept: choosing the finding, records, matching
    state.py              # per-user state folder: turn marks, accepted.jsonl
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

**Where each step runs.** Build on Linux. Nothing here needs .NET or
Windows to parse C#, because tree-sitter reads the source text. Windows is
needed twice, marked **[Windows]** below: once to try the tool on real C#
code (the user's work repos are on the Windows machine), and once for the
final Windows check. When a **[Windows]** step comes up, stop, tell the user,
and make sure everything before it is committed and pushed. Bring back only
generic findings (for example "primary constructors give parse errors"),
never client code, paths or names. If a C# work repo is cloned on the Linux
machine, step 7a can run there instead.

**CRLF from the start.** Many Windows repos use CRLF line endings. From step
2 on, every language's fixtures include at least one CRLF file, with the
same expected findings and line numbers as its LF twin. Mark the fixtures
`-text` in a `.gitattributes` under `tests/fixtures/`, so `core.autocrlf` on
Windows doesn't rewrite their line endings.

1. ✅ **Spike the grammars.** Done: nine languages parse (Python added
   afterwards), node types are in `languages.py`, and SQL was dropped (see
   "Revisit: SQL"). Create the uv
   project. Write a test that parses one sample per language (C#, TS, TSX, JS, JSX, bash, PowerShell, Lua,
   Rust, T-SQL) with no ERROR nodes, and record each language's node type
   names. If PowerShell, C# or T-SQL is missing from the language pack or
   parses badly, **stop and report to the user** with the alternatives (a
   separate grammar package, or a token-based fallback for SQL). Checked by
   pytest.
2. ✅ **Metrics for TypeScript.** Done: `measure_file()` in `measure.py`.
   The rules it settled are tested in `tests/test_measure.py`: nested
   functions are measured on their own, anonymous ones are named
   `<parent>.<callee> callback` or `<parent>.<anonymous>`, and only `try`
   (not `catch`) adds a nesting level. Original scope:
   (functions, CC, nesting, bumps, conditionals,
   params, LOC). TDD with fixtures. Checked by pytest.
3. ✅ **Smells and score for TypeScript**, plus the three calibration
   fixtures. Done: v1 4.1, v2 9.0, v3 10.0. Each smell gives at most one
   finding per function; Complex Conditional reports the worst condition,
   and Large File is reported against `<file>`.
   Checked by pytest (v1 ≤ 4.5 < v2 < v3 = 10.0).
4. ✅ **`score` and `review`** with text and `--json` output. Done: the
   formats are pinned in `tests/test_cli.py`. `.agents/check` prints SKIP
   when `uv` is missing, until step 11 installs it on Windows. Add
   `uv run --project agents/.agents/tools/code-health pytest` to
   `.agents/check`. Checked by CLI tests.
5. ✅ **`safeguard`** Done. A changed file that no longer parses is shown as
   "not scored" and doesn't fail; a baseline that didn't parse counts as
   empty. A rename only keeps its baseline when git sees it (`git mv`, or a
   staged delete and add); a plain `mv` shows as a new file. Text output
   replaces characters the console can't encode. Original scope:
   (changes vs HEAD, and `--base`). Checked by tests on
   temporary git repos: unchanged, worse, not worse in a red file, new file,
   rename, deleted.
6. ✅ **Claude adapter**, settings entries, `test-hooks.sh` cases and the
   AGENTS.md definition-of-done line. Done: the hook takes 0.17s on a
   two-file change. It runs `code-health` from PATH, else
   `uv run --project ~/.agents/tools/code-health`; `CODE_HEALTH_CMD`
   overrides both. Still open: whether `!` commands in Claude Code get a
   terminal (the user will check). Checked by `test-hooks.sh` and a live
   run in a scratch repo.
7. **Languages, one commit each:** C#, Python, JS/JSX/TSX, bash,
   PowerShell, Lua, Rust. C# comes first so step 7a can happen early, then
   Python so the tool checks its own code. Each language
   needs fixtures for every smell, plus `<script>` handling where it
   applies. Checked by pytest.
   - ✅ **C#.** Choices tested in `tests/test_measure_csharp.py`:
     - A primary constructor on a class or struct is a constructor named
       `<Class>.<primary constructor>`; a positional record's isn't.
     - Overloads that would share a name get their parameter types, like
       `C.M(int)`. Other duplicate names, in any language, get `#2`, `#3`.
     - Pattern `and`/`or` count like `&&`/`||`. `default` sections and `_`
       arms don't count. Methods without a body are skipped.
   - ✅ **Python.** `self`/`cls` and the `/` and `*` separators aren't
     parameters; `__init__` is the constructor; `case _:` doesn't count.
     `<script>` (top-level code, all script languages) is exempt from
     Large Method, because modules are mostly data and definitions; Large
     File still applies. Revisit that at calibration. The tool's own code
     scores 10.0.
   - ✅ **JS, JSX, TSX.** Smell fixtures; generator expressions added;
     `&&` and `?:` in JSX count as decisions.
   - ✅ **bash.** `*)` doesn't count; functions take no declared
     parameters, so Excess Function Arguments never applies.
   - ✅ **PowerShell.** Names come from `function_name`/`simple_name`; a
     class method named after its class is the constructor; parameters are
     found in `param(...)` or `function F($a)`. Pipeline script blocks
     (`ForEach-Object { }`) count toward the enclosing function.
   - ✅ **Lua.** `M.f` and `M:g` keep their table prefix; comment lines
     are no longer counted as code in any language.
   - ✅ **Rust.** Methods are qualified by their `impl` or `trait` type;
     `self` isn't a parameter; `_` arms don't count; `?` isn't a decision.
   - **7a, first pass (Linux, open-source code).** Run on dotnet/eShop (about
     26,000 lines, 538 C# files) in a temporary clone; nothing from it is in
     this repo. Results: 536 files parsed; only 28 had findings; Excess
     Function Arguments fired on one DI constructor, at its limit. Changes
     made: skip files whose header says `<auto-generated`, `@generated` or
     `DO NOT EDIT`; blank C# `#if` lines before parsing; stop excluding
     `build/` and `bin/`; treat .NET project and config files as data; cap
     repeats of one smell per file (scorer version 2). EF migrations without
     a marker are left to per-repo config. Still to do on Windows: the same
     look at the user's own work code.
   - **7a. [Windows] C# on real code**, once C# lands, about 30 minutes.
     Pull, run `uv tool install --editable ~/.agents/tools/code-health`, and
     run `code-health review` on about 10 C# files from real work repos. Pick
     a mix: a large service class, a controller, a DI-heavy constructor,
     tests, and a file using recent syntax (records, primary constructors,
     file-scoped namespaces, pattern matching).
     - Check: no parse errors; the scores match what a reader would expect;
       no smell fires on almost everything (Excess Function Arguments on DI
       constructors is the likely one).
     - Bring back generic notes only, and turn each into a synthetic fixture
       or a limit change on Linux.
8. ✅ **Config, ignore comments and `accept`.** Done in four parts:
   8a turn-start base (`mark-turn`, `--since-turn`, the `UserPromptSubmit`
   hook); 8b `.code-health.toml`; 8c ignore comments; 8d `accept`, tested
   with a real pseudo-terminal on Linux. Original scope: checked by pytest, with a test
   that `accept` refuses without a terminal.
9. ✅ **`code-health repo`.** Done. Changes from the original scope:
   the page data is one `.code-health/repo/data.json`, not TSV tables;
   hotspot health is over a fixed 10 busiest files, so it compares across
   runs with different `--top`; `repo-health.sh` and the lizard paragraph
   in `docs/install-windows.md` stay until step 11, which swaps the
   AGENTS.md line in the same change. This repo's `.code-health.toml`
   excludes the tool's smelly test fixtures. Original scope: port churn,
   author density, coupling
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
10. ✅ **Episodes, global history and token capture.** Done. Checked
    against a real transcript: one message spans several lines with the
    same usage, so each `message.id` counts once. Subagents write separate
    transcripts, so their tokens are not counted (a known gap). `iterations`
    counts Claude turns while the episode is open, starting at 1. `safeguard
    --episode` counts the turn, opens or closes the `safeguard-fix` episode
    and flushes ended episodes; bookkeeping errors never change its verdict.
    Global records need `CODE_HEALTH_HISTORY_DIR` (a private repo the user
    sets up); without it they are skipped with a one-time note. Original
    scope: episodes, global history and token capture, with episode start and
    end added to the `refactor` skill. Checked by pytest with a synthetic
    transcript and a key-allowlist test on global records.
11. ✅ **Install wiring.** Done: `./install.sh code-health`
    (`install/install-code-health.sh`, run on Linux) and
    `install/windows/install-code-health.ps1` (run it in step 12) install
    the tool editable with uv and run the new `code-health grammars`, which
    downloads every grammar and prints the cache folder (on Linux,
    `~/.cache/tree-sitter-language-pack/<version>/libs`; confirm the
    Windows one in step 12). `repo-health.sh` and lizard are retired, and
    the definition of done uses `code-health review`. Original scope:
    also, in one change: remove the `repo-health.sh <file>`
    line from AGENTS.md "Definition of done" (deferred from step 6), delete
    `repo-health.sh`, and drop the lizard paragraph from
    `docs/install-windows.md` (both deferred from step 9).
    - Linux: `uv` is already in `nix/.config/nix/home.nix` (pulled forward
      for step 1). Add an install step that runs
      `uv tool install --editable ~/.agents/tools/code-health`, following
      the `STEPS` pattern in `install.sh`.
    - Windows: add `uv` to `packages/scoop-packages.txt`, and a script or
      section in `install/windows/` that runs the same command.
    - On both: download the grammars at install time (for example a
      `code-health grammars` command calling the pack's `download()`).
      `tree-sitter-language-pack` fetches each grammar on first use into
      its cache (`~/.cache/tree-sitter-language-pack/` on Linux), so an
      offline first run would otherwise fail. Check where that cache lives
      on Windows.
    - Remove `lizard` from `packages/pip-packages.txt` and `home.nix`.
    - Document it in `docs/install.md` and `docs/install-windows.md`.

    Checked by running the Linux step.
12. **[Windows] Windows check.** Partly done (first pass on 2026-11-23).
    - ✅ Install through the Windows install script. Found: Claude Desktop
      is an MSIX app, so a terminal inside it (its Terminal tab, or Claude's
      own Bash tool) writes AppData into a private copy under
      `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\`. uv's Python
      minor-version junction made there doesn't resolve, and every `uv run`
      fails with "Missing expected target directory for Python minor version
      link" (astral-sh/uv#19622, open; `--reinstall` doesn't repair it).
      Fixed: the install script sets `UV_PYTHON_INSTALL_DIR` and
      `UV_TOOL_DIR` under `%USERPROFILE%\.local\share\uv`.
    - ✅ Grammar cache on Windows:
      `%LOCALAPPDATA%\tree-sitter-language-pack\<version>\libs`.
    - ✅ Python 3.15: the pin moved from 3.13 to 3.15, to match the tool,
      which `uv tool install` puts on the system Python whatever the pin
      says. tree-sitter went to 0.27.0, because 0.26.1 has no 3.15 wheel
      for Windows and would need MSVC to build.
    - ✅ `bash .agents/check` passes on Windows: 484 passed, 7 skipped (the
      pty tests). The Makefile cases in `test-checks.sh` now skip when
      `make` is missing, as the npm and timeout cases already did.
    - ✅ `accept` terminal check: `isatty()` is true for `NUL` on Windows,
      so input from `NUL` got past the check and crashed at the prompt
      (nothing was recorded). It now asks Windows for a real console
      (`GetConsoleMode`). Still to confirm by hand: in Windows Terminal,
      `code-health accept <a clean file> --smell "Large Method" --reason
      test` reaches the finding lookup ("no Large Method finding"), not
      "needs an interactive terminal".
    - Run `safeguard` and the Claude Stop hook in a scratch repo under Git
      Bash; check Windows paths and CRLF files.
    - Run `code-health repo` on the largest C# work repo (about 100k lines)
      and time it.
    - Fix anything Linux-only, or report it.
13. ✅ **History across machines.** Done (13a-13d); change records are
    written by the Stop hook's `safeguard --episode` run. One history in a private git repo of
    JSONL files (decided over a database: no network or credentials in the
    Stop hook, tiny volume, git gives backup; DuckDB can query JSONL).
    - **13a.** Global records go to `episodes-<host>.jsonl` (sanitized
      hostname), so two machines never append to the same file. Readers
      glob `episodes*.jsonl`.
    - **13b.** `code-health history sync`: in `$CODE_HEALTH_HISTORY_DIR`,
      `git pull --rebase --autostash`, commit new lines, push. Manual for
      now; a daily run from the Stop hook can come later.
    - **13c.** `code-health history [--json]`: per kind, language and size
      band: episodes, median tokens, median duration, median score before
      and after, average iterations.
    - **13d.** A `change` record per Claude turn that changed scored files:
      files changed, language, size band, score before and after, findings
      before and after, and the turn's tokens. Same allowlisted keys as
      episodes, `kind: "change"`.
14. ✅ **More smells.** Each with a fix hint, base 1.0, its own commit, and a
    scorer version bump. Limits are starting values, checked against eShop,
    london-sync-music and this repo before landing.
    - **Code Duplication:** a run of at least 10 code lines that appears
      twice in a file, compared after replacing identifiers and literals.
      Reported against the function with the second copy. Fix: Extract
      Function. Calibrated: a window must mix at least 4 line shapes (a
      uniform list or table isn't copied logic), and test files weigh it at
      half, like Large Method (most hits in a client TS repo were repeated
      test setup).
    - **Mocked Own Module (JS/TS tests):** `vi.mock`, `jest.mock` or
      `mock.module` called with a relative path (`./`, `../`). Reported
      against `<file>`, value the number of such mocks. Fix: test through
      the public interface; use an in-memory fake (AGENTS.md rule).
    - **Large Assertion Block (tests):** at least 8 assertion statements in
      a row in one function. Fix: assert on one object; split the test.
    - **Low Cohesion:** a class whose methods form at least 3 groups that
      share no fields (LCOM4; fields found through `this.`/`self.`, plus C#
      fields by name). Fix: Extract Class. Calibrated: constructors,
      property accessors and methods that touch no fields are left out
      (each accessor touches only its own field, so every property became
      a group).
    - **Primitive Obsession (typed languages):** at least 5 parameters
      typed as primitives (string, number, int, bool, ...). Fix: Introduce
      Parameter Object or a value type. Calibrated: at 4, half of eShop's
      hits were message-event constructors and overloads; at 5 its 10 hits
      are real (an address of five strings, a command of 11 primitives).
    - **Overall Code Complexity:** a file with at least 5 functions whose
      average complexity is at least 6 (4 flagged ordinary, readable files
      in this repo and eShop; the real cases averaged 7.6 and 8). Fix: Extract Function; split the
      module.
15. **[Windows] Windows check for 13 and 14,** folded into step 12.

16. **Move the Windows state folder out of AppData.** Proposed, not agreed:
    it changes the "Approving a failure for now" decision, so confirm with
    the user first.
    - **Problem.** The state folder (`accepted.jsonl`, turn marks) is
      `%LOCALAPPDATA%\code-health` on Windows. The hooks run inside Claude
      Desktop, so they read and write the app's private copy; `accept` run
      in Windows Terminal writes the real folder. Seen on the Windows
      machine: two `code-health\<repo key>\` folders for the same repo, one
      in each place. An acceptance made in a normal terminal can be
      invisible to the Stop hook, and turn marks can split the same way.
    - **Proposal.** Use `~/.local/state/code-health` on every platform:
      delete the `win32` branch in `state.state_dir()`. MSIX only redirects
      AppData, so both sides see the same folder, and there is one rule
      instead of two. `XDG_STATE_HOME` and `CODE_HEALTH_STATE_DIR` still
      override it. Update the "Approving a failure for now" row to match.
    - **Migration.** None. Acceptances lapse anyway when a function changes,
      and turn marks are per session. Say in `docs/install-windows.md` that
      the old `%LOCALAPPDATA%\code-health` can be deleted.
    - **Leave alone.** The grammar cache is also under `%LOCALAPPDATA%`, but
      a split cache only costs a second download.
    - **Tests.** `state_dir()` already takes `env`, `platform` and `home`,
      so plain-value tests cover it: `win32` with no overrides →
      `<home>/.local/state/code-health`; `XDG_STATE_HOME` and
      `CODE_HEALTH_STATE_DIR` still win. Then the Windows test from step 12:
      `accept` in Windows Terminal, and the Stop hook in Claude Desktop sees
      it.

Later: an MCP server wrapping `--json` (tools like `score`, `review`,
`safeguard`), adapters for other harnesses (OpenCode, Codex), Brain Class,
duplication across files, and calibrating against the CodeScene trial on
about 20 files. Also the Rust port (see Decisions): step 12 found that the
Windows install is the fragile part (uv-managed Python, an environment, a
grammar download), and one binary with the grammars compiled in would remove
all three. Do it after 7a and 12, once the rules stop changing, as its own PR.

## Revisit: SQL

Dropped from v1 after step 1. Revisit once v1 is done.

What step 1 found (tree-sitter-language-pack 1.25.2):
- The pack's `tsql` grammar is broken: `select a from t` gives ERROR nodes,
  while `select 1` parses.
- The generic `sql` grammar (the same one PyPI ships as `tree-sitter-sql`)
  parses `SELECT`, `CASE` and subqueries, but none of T-SQL's procedural
  syntax: `DECLARE`, `IF … BEGIN`, `WHILE`, `CREATE PROCEDURE`/`FUNCTION`,
  `TRY`/`CATCH` or `GO`.
- PyPI has no other T-SQL tree-sitter grammar.

Options:
1. A token scanner. Skip comments and strings, split batches on `GO`, find
   `CREATE PROC`/`FUNCTION`/`TRIGGER` boundaries, track nesting through
   `IF`/`WHILE`/`BEGIN…END`/`CASE…END`/`TRY`/`CATCH`, and count
   `AND`/`OR`. Detect a correlated subquery as a `(SELECT …)` in the select
   list that names an outer alias.
2. The scanner for procedure structure, plus the `sql` grammar for each
   `SELECT` statement, which gives a real tree for the subquery check.
3. sqlglot, a Python SQL parser with a T-SQL dialect. Untested so far.

What SQL support needs, from the v1 design:
- The smell "Correlated Subquery in SELECT": a subquery in the SELECT list
  that references the outer query. Fix: rewrite as a JOIN (also a rule in
  AGENTS.md).
- Procedures, functions and triggers count as functions. `IF`, `WHILE`,
  `CASE WHEN` and `BEGIN TRY` count as branches and nesting. Top-level batch
  code is the `<script>` pseudo-function.
- In the user's repos, procedures live inside migration scripts, so
  migrations must **not** be excluded by default.
- On Windows, try it on one real T-SQL migration that contains a stored
  procedure.

## Risks

- **Grammar gaps** (PowerShell, newer C#). Step 1 tested this: C# with
  newer syntax parses, PowerShell fails on `??`, and T-SQL was dropped. An
  unparseable file is "not scored", never 10.
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
