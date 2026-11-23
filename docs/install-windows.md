# Windows Clean system (re)install guide

This document describes the first-boot process and setup steps for a Windows machine using these dotfiles. It is the companion to `docs/install.md` (Linux guide).

## Scope

This guide covers initial environment setup *after* Windows has finished installation, up to and including:
- Getting online and authenticating to Microsoft (or local) user account
- Installing a browser and password manager
- Creating or restoring SSH keys for GitHub
- Cloning the dotfiles repo
- Bootstrapping the core CLI/tooling environment with Scoop
- Installing Node via mise and the npm-based language servers

## Prerequisites

- Fresh Windows install (ideally Windows 11)
- Administrator access on the device
- Internet connection
- Credentials for password manager, GitHub, and email

## Manual steps (before automation)
1. Connect to Wi‑Fi or Ethernet
2. Log into password manager and email
3. Complete 2FA if required
4. Download your terminal of choice (recommended: [WezTerm](https://wezfurlong.org/wezterm/))
5. Optionally, restore previous SSH keys, or generate new ones with PowerShell

### Generate a new SSH key (if needed)
```powershell
ssh-keygen -t ed25519 -C "your_email@example.com"
```
Add the public key to your GitHub account: https://github.com/settings/keys

## Cloning the repo
Open PowerShell (or terminal) and run:
```powershell
git clone git@github.com:pcfields/dotfiles.git
```

## Automated install steps
Change to the dotfiles repo and run Scoop installer:
```powershell
cd dotfiles
powershell -ExecutionPolicy Bypass -File install\windows\install-scoop.ps1
```
This will:
- Install Scoop if missing
- Add required buckets (extras, nerd-fonts, versions)
- Install all core CLI tools, TUI/editor apps, Nerd Fonts (from `packages/scoop-packages.txt`)
- Install `mise`, which provides language runtimes (as it does on Linux)

### Node and the npm-based tooling

Some developer tooling ships as npm packages rather than standalone binaries, so
scoop has no manifest for it. On Linux these come from Nix; on Windows they come
from npm. This is the one place where Windows needs a package manager Linux does
not, and it is deliberate rather than an oversight.

Install Node through mise, then the packages. Windows does not link the repo's
mise config, so this sets the version in your own global config; keep it in
step with `mise/.config/mise/config.toml`. Global npm packages live inside each
Node major version, so re-run the second command after changing it:

```powershell
mise use --global node@26
powershell -ExecutionPolicy Bypass -File install\windows\install-npm-globals.ps1
```

This installs everything in `packages/npm-global-packages.txt`:

| Package | Provides |
|---|---|
| `@vtsls/language-server` | `vtsls` — the TypeScript/JavaScript language server |
| `vscode-langservers-extracted` | `jsonls`, `cssls`, `eslint`, `html` |
| `@olrtg/emmet-language-server` | `emmet_language_server` |
| `@tailwindcss/language-server` | `tailwindcss` |
| `graphql-language-service-cli` | `graphql` |
| `yaml-language-server` | `yamlls` |
| `bash-language-server` | `bashls` |
| `dockerfile-language-server-nodejs` | `dockerls` |
| `@taplo/cli` | `taplo` |
| `prettier` | formatter fallback where biome does not apply |

The Scoop step supplies the remaining web/config tools: `biome`,
`lua-language-server`, `marksman`, `shellcheck`, `shfmt`, and `stylua`.

Without this step Neovim starts cleanly but silently has no TypeScript
intelligence — no completion, no go-to-definition, no diagnostics. The failure
is quiet, so check it explicitly:

```powershell
where.exe vtsls
```

Then open a `.ts` file in Neovim and run `:checkhealth lsp`; `vtsls` should be
listed as attached.

#### If a server fails to start

A global npm install on Windows writes two files per binary: a bare shell script
and a `.cmd` wrapper. Neovim can spawn the `.cmd` but not the bare shim, so a
server whose configured command resolves to the shim will fail to launch. If
`:checkhealth lsp` reports a server that will not start, check which one is being
found:

```powershell
where.exe <server-name>
```

If the `.cmd` is absent, reinstall that package. `format.lua` already applies
this workaround for prettier and documents the reasoning.

### code-health

`code-health` scores code health for the agent hooks and the `repo-health`
skill. It installs with `uv` (from scoop) as an editable tool, and downloads its
tree-sitter grammars so a first run works offline:

```powershell
powershell -ExecutionPolicy Bypass -File install\windows\install-code-health.ps1
```

Open a new terminal afterwards, then check it with `code-health grammars`, which
also prints where the grammars are cached. Re-run the script after the tool's
dependencies change; code changes take effect without it.

**Quit Claude Desktop from its tray icon after `scoop install uv`.** Scoop's uv
sets `UV_PYTHON_INSTALL_DIR`, `UV_TOOL_DIR` and friends for your user, pointing
at `scoop\persist\uv`. Claude Desktop only sees them after a full restart;
closing its window leaves it running in the tray. Until then, uv falls back to
`%APPDATA%`, and Claude Desktop is an MSIX app: a terminal inside it writes
AppData into a private copy, where uv's Python junctions don't resolve
([astral-sh/uv#19622](https://github.com/astral-sh/uv/issues/19622)). The
symptom is `Missing expected target directory for Python minor version link`.

Because of that private copy, code-health keeps its state (acceptances from
`code-health accept`, and turn marks) in `%USERPROFILE%\.local\state\code-health`,
not AppData, so the Claude hooks and a normal terminal see the same folder.
Older versions used `%LOCALAPPDATA%\code-health`; that folder can be deleted.

`packages/pip-packages.txt` is kept for Python-based tools without a scoop
manifest, and is empty at the moment.

**Next, you MUST set up symlinks for your PowerShell profile and other configs:**
```powershell
powershell -ExecutionPolicy Bypass -File install\windows\setup-windows-symlinks.ps1
```
This safely symlinks your PowerShell profile (`profile.ps1`) to `$PROFILE` so all aliases, functions, and Oh My Posh setup work. Also links WezTerm, nvim, and other config files as needed, plus the shared agent config (`~/.agents`, Claude skills, `~/.codex/AGENTS.md`).

After adding, renaming or removing a skill in `agents\.agents\skills`, relink just the skills. This needs no Administrator prompt, because skills are linked with directory junctions:
```powershell
powershell -ExecutionPolicy Bypass -File install\windows\link-agent-skills.ps1
```
Then run `/reload-skills` in Claude Code, or start a new session.

## Shell, Aliases, and Profile
All PowerShell config (profile, aliases, helper functions) is managed in the `powershell/` directory and sourced by the symlinked profile. Edit in the repo for instant propagation.
- Aliases are harmonized with the fish shell equivalents for consistency.
- Do **not** manually symlink config files yourself—always use the provided helper script for idempotence and safety.

## Fonts
Terminal and editor fonts (such as Monaspace Neon and JetBrainsMono Nerd Font) are installed via Scoop for use in WezTerm or other terminals.
- After font install, restart your terminal and select the Nerd Font as desired.

## Post-install tasks
- Reconnect other accounts/SSH keys as needed
- Authenticate tools like GitHub, etc.
- Set environment variables and secrets manually after install (see `docs/secrets.md`)

---

For troubleshooting and advanced edits, see also:
- `docs/terminal.md` (terminal best practices for Linux and Windows)
- `docs/strategy.md` (rationale for cross-platform package management)
