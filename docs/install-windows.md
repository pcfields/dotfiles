# Windows Clean system (re)install guide

This document describes the first-boot process and setup steps for a Windows machine using these dotfiles. It is the companion to `docs/install.md` (Linux guide).

## Scope

This guide covers initial environment setup *after* Windows has finished installation, up to and including:
- Getting online and authenticating to Microsoft (or local) user account
- Installing a browser and password manager
- Creating or restoring SSH keys for GitHub
- Cloning the dotfiles repo
- Bootstrapping the core CLI/tooling environment with Scoop

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

**Next, you MUST set up symlinks for your PowerShell profile and other configs:**
```powershell
powershell -ExecutionPolicy Bypass -File install\windows\setup-windows-symlinks.ps1
```
This safely symlinks your PowerShell profile (`profile.ps1`) to `$PROFILE` so all aliases, functions, and Oh My Posh setup work. Also links WezTerm, nvim, and other config files as needed.

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
