# OpenCode-specific rules

The shared global instructions live in `~/.agents/AGENTS.md` and are loaded via
`instructions` in `opencode.json`. Only OpenCode-specific rules belong here.

## Cost Habits

- One task per session where practical — start a new session once a task
  completes rather than layering unrelated work onto one long chat.
- Hand off state as files (plans, diffs), not accumulated chat history.
- Default to Sonnet; don't reach for a bigger model preemptively. Escalate
  via manual `/model` only after Sonnet has genuinely stalled, and switch
  back once the hard part is solved.
- Use `/commit`, `/test`, and `/review` for the scoped, cheaper-model work
  they're built for instead of doing it inline on the default model.
