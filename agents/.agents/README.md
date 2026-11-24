# Agent skills and tools: getting started

Skills, hooks and a code-health tool for AI coding agents, mainly Claude
Code. Codex and OpenCode read the same skills. They come from a personal
dotfiles repo, so copy the parts you want and make them yours.

## What's here

| Part | What it does | Needs |
|---|---|---|
| `skills/plan-it` | Turns a request into an agreed plan: examples, design, small steps | — |
| `skills/challenge` | Pokes holes in a plan, design or diff | — |
| `skills/tdd` | Test-first loop (Kent Beck's Canon TDD), test-double rules | `skills/refactor/refactorings.md` |
| `skills/debug-it` | Finds the root cause from evidence before fixing | `tdd` |
| `skills/commit` | Plans and makes conventional commits, split by concern | `lib/`, bash |
| `skills/pr-draft` | Drafts a PR title and description for the branch | `lib/`, bash |
| `skills/refactor` | Tidies or uplifts code in small tested steps | `tdd`; `code-health` for an uplift |
| `skills/repo-health` | Ranks hotspots by change frequency and code health | `code-health`, uv |
| `AGENTS.md` | Global instructions loaded into every session | — |
| `checks/run-project-check.sh` | Runs a repo's `check` command when the agent stops | bash |
| `tools/code-health` | Scores files 1-10 and names the code smells in each | uv |
| `../../claude/.claude/hooks/` | Claude Code hooks: block secret files and destructive commands, run checks on stop | bash, jq |

Skills mention each other by name (`plan-it` hands off to `tdd`). Any one
works alone, but they work best together.

## 1. Skills

Keep the folder at `~/.agents`: some skills run scripts from
`~/.agents/skills/...`, and `commit` and `pr-draft` need `~/.agents/lib`.

Linux and macOS:

```bash
git clone --depth 1 https://github.com/pcfields/dotfiles.git /tmp/pcf-dotfiles
```

```bash
cp -r /tmp/pcf-dotfiles/agents/.agents ~/.agents
```

```bash
mkdir -p ~/.claude/skills && ln -s ~/.agents/skills/* ~/.claude/skills/
```

Windows (PowerShell, no admin needed):

```powershell
git clone --depth 1 https://github.com/pcfields/dotfiles.git $env:TEMP\pcf-dotfiles
Copy-Item -Recurse $env:TEMP\pcf-dotfiles\agents\.agents $HOME\.agents
New-Item -ItemType Directory -Force $HOME\.claude\skills | Out-Null
Get-ChildItem $HOME\.agents\skills -Directory | ForEach-Object {
  New-Item -ItemType Junction -Path "$HOME\.claude\skills\$($_.Name)" -Target $_.FullName
}
```

The bash scripts need Git Bash on Windows.

Start a new Claude Code session and type `/` to see the skills. Try
`/plan-it` on a small change, let it hand off to `/tdd`, then `/commit`.
Codex and OpenCode find `~/.agents/skills` without the links.

## 2. Instructions (optional)

`AGENTS.md` holds one person's working style: tidy first, functional core,
test-first, commit rules. Read it, keep what suits you and delete the rest.
For Claude Code, load it from `~/.claude/CLAUDE.md`:

```markdown
@~/.agents/AGENTS.md
```

## 3. Safety and check hooks (Claude Code)

Copy `claude/.claude/hooks/` from the clone to `~/.claude/hooks/`, install
`jq`, and merge this into `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Read|Edit|Write|Grep",
        "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/protect-secrets.sh\"" }] },
      { "matcher": "Bash|PowerShell",
        "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/block-catastrophic-bash.sh\"" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/run-check-on-stop.sh\"", "timeout": 180 }] }
    ]
  }
}
```

- `protect-secrets` stops the agent reading `.env`, keys and credential files.
- `block-catastrophic-bash` stops `rm -rf ~`, `mkfs`, force-pushes to main and
  similar.
- `run-check-on-stop` runs the repo's `check` command (from `.agents/check`,
  `package.json`, `justfile`, `Makefile` or `mise.toml`) when the agent
  finishes, and sends failures back to it.

They are a backstop. Keep Claude Code's sandbox and permission prompts on.

## 4. code-health

Install [uv](https://docs.astral.sh/uv/), then:

```bash
uv tool install --editable ~/.agents/tools/code-health && code-health grammars
```

Try it in any repo: `code-health review <file>`, or `/repo-health` for a full
report. To have it check every change the agent makes, copy the hooks as in
step 3 and add these to `settings.json` (the `Stop` entry joins the list
from step 3):

```json
"UserPromptSubmit": [
  { "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/code-health-turn-start.sh\"", "timeout": 30 }] }
],
"Stop": [
  { "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/code-health-on-stop.sh\"", "timeout": 60 }] }
]
```

Only you should accept a finding, never the agent. Add
`"Bash(code-health accept:*)"` to `permissions.deny` in `settings.json`.
`tools/code-health/README.md` explains the scores.

Each run writes to a `.code-health/` folder in the repo and adds it to
`.git/info/exclude`, so it never shows up in `git status`.

## Make it yours

- **Change a skill:** edit its `SKILL.md`; it's plain Markdown.
- **Team or company rules:** put them in an overlay instead of editing the
  skill, so you can copy a newer version over without losing them. List
  your repos in `~/.agents-local/contexts.txt`, one line per pattern that
  matches the origin URL:

  ```text
  git.example.com/team work base=origin/develop
  ```

  Then write `~/.agents-local/overlays/commit/work.md` (or `pr-draft/`)
  with the extra rules. `base=` sets the branch `pr-draft` compares with.
- **Opinions to check before using:** `commit` forbids `Co-Authored-By`
  trailers, `pr-draft` keeps descriptions under about 15 lines, and `tdd`
  includes React Testing Library rules. Change them if your team works
  differently.
- **Update:** clone again and copy the folders over. Your overlays live in
  `~/.agents-local`, so they are kept.
