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
- **Perplexity** — set `PERPLEXITY_API_KEY` in your shell environment (used by `researcher` agent)
- **Other providers** — see https://opencode.ai/docs/providers

To set API keys persistently in Fish shell:
```fish
set -Ux ANTHROPIC_API_KEY sk-ant-xxxxx
set -Ux PERPLEXITY_API_KEY pplx-xxxxx
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

### code-health

The `code-health` install step downloads the binary from a release of a
private GitHub repo, which this public repo doesn't name. Set
`CODE_HEALTH_REPO` to that repo's `<owner>/<name>`:

```fish
set -Ux CODE_HEALTH_REPO <owner>/<name>
```

```powershell
[Environment]::SetEnvironmentVariable("CODE_HEALTH_REPO", "<owner>/<name>", "User")
```

`gh` needs a token to download the release. Don't use `gh auth login`: it
leaves a login to the whole GitHub account on the machine. Create a
fine-grained personal access token instead:

- **Repository access:** only the code-health repo, plus the history repo if
  this machine syncs history, and this repo if you push from the machine.
- **Permissions:** Contents, read and write. Read-only is enough if the token
  only downloads the release.
- **Expiration** set, and a name that says which machine holds it.

Give it to `gh` for the install command only:

```fish
env GH_TOKEN=(read -s -P 'token: ') ./install.sh code-health
```

```powershell
$env:GH_TOKEN = Read-Host -MaskInput "token"; powershell -ExecutionPolicy Bypass -File install\windows\install-code-health.ps1; Remove-Item Env:GH_TOKEN
```

`Read-Host -MaskInput` needs PowerShell 7. Afterwards, `gh auth status` should
say you're not logged in.

### Personal repos on a work machine (Windows)

Git Credential Manager saves one login for all of github.com, and its browser
and device sign-ins grant access to every repo. Close those windows if they
appear. To use the fine-grained token for one repo only, run this in each
personal repo that needs to fetch or push:

```powershell
git config credential.useHttpPath true
git config credential.username <github-user>
git config credential.gitHubAuthModes pat
```

The next `git fetch` asks for a token: paste the fine-grained one. Then
`cmdkey /list | Select-String github` should show that repo's URL, not plain
`git:https://github.com`.

## Environment Variables

These should be set in your shell config (Fish):

| Variable | Value | Set in |
|----------|-------|-------|
| `EDITOR` | `nvim` | Fish config |
| `VISUAL` | `nvim` | Fish config |
| `MANPAGER` | `sh -c 'col -bx \| bat -l man -p'` | Fish config |

## Backup Checklist

Before a clean install, back up:

- [ ] SSH keys (`~/.ssh/`)
- [ ] GPG keys (`gpg --export-secret-keys > backup.gpg`)
- [ ] Fish universal variables (`~/.config/fish/fish_variables`) — contains API keys
- [ ] Any project-level `.env` files
- [ ] Browser bookmarks and passwords (if not synced)
- [ ] Any local databases or data files
