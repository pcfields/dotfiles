# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal dotfiles and machine-setup repo for **two targets from one tree**: Ubuntu-based Linux (mainly Pop!_OS) and Windows (Scoop + PowerShell). There is no application to build or test — the "code" is install scripts and config files. Changes are validated by re-running the relevant install step, not a test suite.

## Workflow

`AGENTS.md` sets the rule: **ask for confirmation before making changes**, even when the change seems obvious. Do not assume and proceed.

## Two config-linking mechanisms (the core architecture)

Configs live in the repo and are **symlinked** into their real locations. The linking tool differs by OS — this is the single most important thing to understand:

- **Linux → GNU Stow.** Each top-level dir (`fish/`, `git/`, `nvim/`, …) is a *stow package* whose internal layout mirrors `$HOME`. Example: `nvim/.config/nvim/init.lua` → `~/.config/nvim/init.lua`. The package list lives in `install/stow-dotfiles.sh` (`STOW_PACKAGES`). Adding a config on Linux means: create `myapp/.config/myapp/…`, add `myapp` to `STOW_PACKAGES`, run `./install.sh stow`.
- **Windows → explicit symlinks.** `install/windows/setup-windows-symlinks.ps1` hardcodes each `Source → Target` mapping and must run **as Administrator** (symlinks need elevation). It detects the real user profile via the owner of `explorer.exe` so paths resolve correctly under "Run as Administrator", and backs up any pre-existing config before linking. Adding a Windows config means editing the `$Links` array (or the PowerShell-profile block) in that script.

The same `nvim/.config/nvim/` tree is consumed by both mechanisms — keep the stow-style directory layout even for Windows-only additions.

## Install orchestration (Linux)

`./install.sh` is the entry point. It runs ordered steps and records progress in `.install-state` (gitignored), so an interrupted run resumes.

```bash
./install.sh              # full flow, resuming completed steps
./install.sh <step>       # single step
./install.sh <step> --force   # re-run an already-completed step
./install.sh reset        # clear .install-state
```

Steps run in this order (defined in `STEPS` in `install.sh`), each dispatching to `install/install-<step>.sh`:

```
apt → stow → fish → fonts → ohmyposh → rustup → nix → flatpak → mise-runtimes → opencode → zsa-wally
```

**Order-dependent restarts:** `fish` and Docker group membership need logout/login; `nix` needs a shell restart before the following step. See `docs/strategy.md` for the rationale behind the ordering.

Install scripts source `lib/common.sh` for shared helpers (`log`, `warn`, `error`, `require_command`, `require_file`, `repo_root`, `read_package_file`). `read_package_file` is what parses the `packages/*.txt` lists (strips `#` comments and blank lines) — reuse it rather than re-parsing.

## Windows setup

```powershell
cd dotfiles
powershell -ExecutionPolicy Bypass -File install\windows\install-scoop.ps1   # Scoop + buckets + tools from packages/scoop-packages.txt
# then, elevated:
.\install\windows\setup-windows-symlinks.ps1                                  # link configs + PowerShell profile
```

`powershell/profile.ps1` is symlinked to `$PROFILE`; it inits Oh My Posh, dot-sources `powershell/aliases.ps1`, and optionally sources `powershell/local-private.ps1` (untracked — for private/work-specific config).

## Package-manager boundaries

Which tool owns what — respect these when adding software (from `AGENTS.md`):

| What | Linux | Windows | Config file |
|---|---|---|---|
| System/GUI apps, Docker | apt | (winget/manual) | `packages/apt-packages.txt` |
| Core CLI dev tools | Nix + Home Manager | Scoop | `nix/.config/nix/home.nix` / `packages/scoop-packages.txt` |
| Sandboxed GUI apps | Flatpak | — | `packages/flatpak-packages.txt` |
| Language runtimes | mise | mise | `mise/.config/mise/config.toml` |
| **LSP servers, formatters, linters** | Nix + Home Manager | Scoop, else npm | `nix/.config/nix/home.nix` / `packages/npm-global-packages.txt` — **not Mason** (Mason handles DAP only) |
| DAP debug adapters | Mason | Mason | `lua/pcf/plugins/debugging/dap.lua` (`ensure_adapters`) — exactly two packages; see `docs/strategy.md` for why Mason and not Nix here |

**Provisioning is split by platform, not by tool type.** Linux gets everything
from Nix. Windows takes what scoop has (`lua-language-server`, `marksman`,
`biome`) and the rest from npm, because servers like `@vtsls/language-server`
and `vscode-langservers-extracted` ship as npm packages and have no scoop
manifest. See `packages/npm-global-packages.txt` and `docs/install-windows.md`.

Two consequences worth remembering: the Windows npm step is manual and easy to
skip, which leaves Neovim running with no TypeScript intelligence and no error
message; and a `# comment` after a package name is stripped on both platforms,
so `packages/*.txt` parse identically (`read_package_file` in `lib/common.sh`,
and the matching regex in the PowerShell installers).

Update installed packages:

```bash
cd ~/.config/nix && nix flake update && home-manager switch --flake .   # Nix/Home Manager
mise install                                                            # runtimes
```

## Neovim config

`nvim/.config/nvim/` is a self-contained Lua config under the `pcf` namespace (`lua/pcf/`), plugin-per-file under `lua/pcf/plugins/<category>/`, managed by lazy.nvim (`lazy-lock.json`). It has its **own `nvim/.config/nvim/AGENTS.md`** with test/format/style conventions — read it before touching nvim code. Key points: tabs (width 4) for Lua / 2 spaces for JS-TS, stylua for Lua formatting, biome preferred for JS/TS, tests via neotest, and `require("pcf.utils").map()` for keymaps.

## Conventions

- Secrets/API keys are **never** committed. See `docs/secrets.md`.
- Bash install scripts use `set -euo pipefail` and the `lib/common.sh` helpers.
- Documentation of intent lives in `docs/` (`install.md`, `install-windows.md`, `secrets.md`, `strategy.md`, `terminal.md`) — consult `docs/strategy.md` for the "why" behind package-manager and ordering decisions.
