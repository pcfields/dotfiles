# Secrets & Environment Variables

> These are things that CANNOT be stored in the dotfiles repo. You need to
> set them up manually after a fresh install.

## API Keys

### OpenCode (AI coding agent)

OpenCode needs an LLM provider API key to function. After installing, run
`opencode` in any project directory and use the `/connect` command to configure.

**Options:**
- **OpenCode Zen** (easiest) — run `/connect`, select "opencode", sign in at
  https://opencode.ai/auth, and paste your API key
- **Anthropic** — set `ANTHROPIC_API_KEY` in your shell environment
- **OpenAI** — set `OPENAI_API_KEY` in your shell environment
- **Other providers** — see https://opencode.ai/docs/providers

To set API keys persistently in Fish shell:
```fish
set -Ux ANTHROPIC_API_KEY sk-ant-xxxxx
```

The `-Ux` flag makes it universal (persists across sessions) and exported
(available to child processes). These are stored by Fish in
`~/.config/fish/fish_variables` — which is NOT tracked in this repo.

### Git (SSH keys & signing)

After a fresh install, you need to:

1. Generate a new SSH key (or restore from backup):
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com"
   ```
2. Add the public key to GitHub: https://github.com/settings/keys
3. Set your git identity (not stored in dotfiles for security):
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your-email@example.com"
   ```

### Proton VPN / Proton Mail

Log in through the GUI apps after installation. Credentials are not stored
in dotfiles.

## Environment Variables Set by Dotfiles

These are already configured in `home.nix` and don't need manual setup:

| Variable | Value | Set by |
|----------|-------|--------|
| `EDITOR` | `nvim` | home.nix |
| `VISUAL` | `nvim` | home.nix |
| `MANPAGER` | `sh -c 'col -bx \| bat -l man -p'` | home.nix |

## Backup Checklist

Before a clean install, back up:

- [ ] SSH keys (`~/.ssh/`)
- [ ] GPG keys (`gpg --export-secret-keys > backup.gpg`)
- [ ] Fish universal variables (`~/.config/fish/fish_variables`) — contains API keys
- [ ] Any project-level `.env` files
- [ ] Browser bookmarks and passwords (if not synced)
- [ ] Any local databases or data files
