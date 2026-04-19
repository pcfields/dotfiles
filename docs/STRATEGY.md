# Dotfiles Strategy & Philosophy

> This document explains the reasoning behind every major decision in this dotfiles
> setup. It exists because this process happens rarely (OS upgrades / clean installs)
> and the details are easy to forget.

## Overview

This dotfiles repo manages a full development environment for Ubuntu-based Linux
distros (Pop!_OS, Ubuntu, etc.) using four
package managers, each with a specific role. The golden rule is:

**Each tool has ONE job. Don't use two tools for the same thing.**

```
┌─────────────────────────────────────────────────────────────────┐
│                        install.sh                               │
│  apt → stow → nix/home-manager → flatpak → mise                │
└─────────────────────────────────────────────────────────────────┘
         │        │            │           │          │
     system    symlink     CLI tools    GUI apps   language
     packages  configs     + shell      (sandboxed) runtimes
```

---

## The Four Package Managers

### 1. APT — System-level packages

**When to use**: System libraries, drivers, build tools, desktop apps that need
deep OS integration, and anything required *before* Nix is installed.

**Why apt and not something else**: APT is the native package manager for
Ubuntu-based distros (Pop!_OS, Ubuntu, etc.). System packages, kernel modules, and hardware drivers
must come from apt. Some GUI apps (VS Code, Slack, Vivaldi, Zoom) only provide
`.deb` packages or apt repos — these go here too.

**Examples**: `build-essential`, `cmake`, `git`, `curl`, `stow`, `code`,
`slack-desktop`, `vivaldi-stable`, `ffmpeg`, `gnome-tweaks`

**Config file**: `packages/apt-packages.txt`

### 2. Nix + Home Manager — CLI dev tools and shell configuration

**When to use**: Developer CLI tools, terminal utilities, shell config (Fish),
and any program where you want a reproducible, declarative setup that doesn't
touch the system package manager.

**Why Nix instead of apt for CLI tools**: Nix provides newer versions than
Ubuntu's repos (e.g., ripgrep, bat, fzf are often years behind in apt). Nix
also lets you declare your entire tool setup in one file (`home.nix`) and
reproduce it exactly on any machine. Home Manager goes further by managing
shell config, git config, fzf settings, etc. — all in one place.

**Why NOT Nix for everything**: Nix has a learning curve and some things don't
work well in its sandboxed environment (see "Why not Nix for Node.js" below).
GUI apps in Nix can have integration issues on non-NixOS systems (font paths,
D-Bus, themes). Keep Nix for what it's best at: CLI tools and config.

**Examples**: `ripgrep`, `fd`, `bat`, `eza`, `lazygit`, `btop`, `oh-my-posh`,
`delta`, Fish shell config, git config, fzf config

**Config files**: `nix/.config/nix/flake.nix`, `nix/.config/nix/home.nix`

### 3. Flatpak — Sandboxed GUI applications

**When to use**: GUI applications that benefit from sandboxing, automatic
updates, and don't need deep system integration.

**Why Flatpak instead of apt for some GUI apps**: Flatpak apps are sandboxed
(more secure), auto-update independently of the OS, and often have newer
versions than apt. Firefox in particular works better as a Flatpak on
Ubuntu-based distros — Mozilla actively maintains it and it gets updates faster.

**When NOT to use Flatpak**: Apps that need tight system integration (VS Code
needs terminal/shell access), apps that only provide `.deb` packages (Slack,
Zoom), or apps where the Flatpak has known sandboxing issues.

**Examples**: OBS Studio, Inkscape, Firefox

**Config file**: `packages/flatpak-packages.txt`

### 4. mise — Programming language runtimes

**When to use**: Any programming language runtime where you need version
switching between projects (Node.js, Python, Elixir, Zig).

**Why mise instead of Nix for language runtimes**: This was a deliberate
decision based on real-world pain:

- **Node.js + Nix is painful**: Nix installs Node.js into a read-only store
  (`/nix/store/...`). This means `npm install -g` doesn't work normally. Node
  resolution and native module compilation can break because paths don't match
  what tools expect. Custom workarounds are needed to make Node.js visible in
  the terminal and to get global packages working. mise avoids all of this.

- **Version switching**: mise lets you pin different versions per-project using
  `.mise.toml` files. A frontend project can use Node 20, while another uses
  Node 22. Nix can do this with flake devshells, but it's much heavier.

- **npm/pip/mix global packages**: With mise, `npm install -g`, `pip install`,
  and `mix archive.install` all work normally because runtimes live in
  `~/.local/share/mise/` (a regular writable directory).

**Exception — Rust stays in Nix**: `rustup` is kept in `home.nix` because
Rust's toolchain management (stable/nightly, components like `rust-analyzer`,
`clippy`, `rustfmt`) is tightly coupled to `rustup`. mise's Rust support is
just a wrapper around `rustup` anyway, so there's no benefit to adding a layer.

**Examples**: Node.js 22, Python 3.12, Erlang 27, Elixir 1.17, Zig latest

**Config file**: `mise/.config/mise/config.toml`

---

## Directory Structure

```
~/dotfiles/
├── install.sh                    # Master installer (run this on fresh system)
├── packages/
│   ├── apt-packages.txt          # apt package list
│   └── flatpak-packages.txt     # Flatpak app list
├── scripts/
│   ├── apt-install.sh            # Adds repos + installs apt packages
│   ├── nix-install.sh            # Installs Nix + runs home-manager
│   ├── flatpak-install.sh        # Adds Flathub + installs Flatpak apps
│   ├── fonts-install.sh          # Downloads + installs fonts
│   └── stow-dotfiles.sh         # Symlinks all config dirs into $HOME
├── nix/.config/nix/
│   ├── flake.nix                 # Nix flake (pinned nixpkgs + home-manager)
│   ├── home.nix                  # Home Manager config (tools + shell)
│   ├── nix.conf                  # Nix settings (enables flakes)
│   └── bootstrap.sh              # Legacy bootstrap (now replaced by nix-install.sh)
├── nvim/.config/nvim/            # Neovim config (stowed to ~/.config/nvim)
├── ohmyposh/.config/ohmyposh/    # Oh My Posh prompt config
├── wezterm/.config/wezterm/      # WezTerm terminal config
└── mise/.config/mise/
    └── config.toml               # Global mise tool versions
```

### How Stow works

GNU Stow creates symlinks from each top-level directory into `$HOME`. The
directory structure inside each "stow package" mirrors the structure you want
in your home directory:

```
dotfiles/nvim/.config/nvim/init.lua  →  ~/.config/nvim/init.lua
dotfiles/nix/.config/nix/flake.nix   →  ~/.config/nix/flake.nix
dotfiles/mise/.config/mise/config.toml → ~/.config/mise/config.toml
```

To add a new config to the dotfiles repo:
1. Create a directory: `dotfiles/myapp/.config/myapp/`
2. Put your config files inside it
3. Add `myapp` to the `STOW_PACKAGES` array in `scripts/stow-dotfiles.sh`
4. Run `./install.sh stow`

---

## Installation Order (and why it matters)

```
1. apt       — Must come first. Installs git, curl, stow, mise, and system deps.
2. stow      — Symlinks configs into $HOME so Nix can find flake.nix, home.nix, etc.
3. fonts     — Installs Monaspace Neon, JetBrains Mono, MesloLGS Nerd Font.
4. nix       — Installs Nix daemon, then runs home-manager to set up CLI tools + Fish.
5. flatpak   — Installs sandboxed GUI apps from Flathub.
6. mise      — Installs language runtimes (needs mise binary from apt step).
7. opencode  — Installs OpenCode AI coding agent (needs curl from apt step).
8. neovim    — Downloads latest stable Neovim from GitHub releases to ~/.local/.
```

**Why this order**: Each step depends on the previous one. Stow needs `stow`
from apt. Nix needs the flake.nix to be symlinked by stow. mise needs the
binary installed by apt.

---

## How to Run

### Fresh install (everything)

```bash
# 1. Clone the repo
git clone https://github.com/pcfields/dotfiles.git ~/dotfiles

# 2. Run the master installer
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Run individual steps

```bash
./install.sh apt       # Only apt packages
./install.sh stow      # Only symlink configs
./install.sh nix       # Only Nix + home-manager
./install.sh flatpak   # Only Flatpak apps
./install.sh mise      # Only mise runtimes
./install.sh opencode  # Only OpenCode
./install.sh fonts     # Only fonts
```

### Day-to-day changes

| Task | Command |
|------|---------|
| Add an apt package | Add to `packages/apt-packages.txt`, run `./install.sh apt` |
| Add a CLI tool via Nix | Add to `nix/.config/nix/home.nix`, run `home-manager switch --flake ~/.config/nix` |
| Add a Flatpak app | Add to `packages/flatpak-packages.txt`, run `./install.sh flatpak` |
| Change a language version | Edit `mise/.config/mise/config.toml`, run `mise install` |
| Pin a project to a specific Node version | Create `.mise.toml` in project dir with `node = "20"` |
| Add a new dotfile config | Create `dotfiles/appname/.config/appname/`, add to `stow-dotfiles.sh`, run `./install.sh stow` |
| Update all Nix packages | `cd ~/.config/nix && nix flake update && home-manager switch --flake .` |

---

## Adding New Software — Decision Framework

When you want to add a new tool or app, walk through this flowchart:

### Step 1: What kind of software is it?

```
Is it a programming language runtime?
  → YES: Use mise. Add to mise/.config/mise/config.toml
         Exception: If the language has its own superior version manager
         (like rustup for Rust), use that via Nix instead.

Is it a CLI dev tool? (grep replacement, git TUI, file viewer, etc.)
  → YES: Use Nix home-manager. Add to nix/.config/nix/home.nix
         Nix gives you newer versions than apt and keeps everything
         declarative in one file.

Is it a GUI desktop app?
  → Go to Step 2.

Is it a system-level dependency? (driver, library, kernel module, build tool)
  → YES: Use apt. Add to packages/apt-packages.txt
```

### Step 2: Choosing the right source for GUI apps

```
Does the app need deep system access?
  (terminal integration, file system access, hardware, extensions)
  → YES: Use apt. Examples: VS Code, Slack
         Flatpak sandboxing breaks these apps.

Does the app have a well-maintained Flatpak on Flathub?
  → YES: Prefer Flatpak. Examples: Firefox, OBS, Inkscape
         Benefits: sandboxed, auto-updates, isolated from OS upgrades.

Is the app only available as a .deb or apt repo?
  → YES: Use apt. Examples: Vivaldi
         Add the repo setup to scripts/apt-install.sh

Is the app a standalone binary with its own installer?
  → YES: Add a curl/wget install step to install.sh
         Example: OpenCode
```

### Step 3: Does it have config files?

```
Does the app store config in ~/.config/appname/ (or similar)?
  → YES:
    1. Create dotfiles/appname/.config/appname/
    2. Move your config files there
    3. Add "appname" to STOW_PACKAGES in scripts/stow-dotfiles.sh
    4. Run: ./install.sh stow

Does it need environment variables or API keys?
  → YES: Document them in docs/SECRETS.md
         Do NOT put secrets in the repo.
```

### Step 4: Log the decision

Add a row to the Decision Log table at the bottom of this file. Include:
- The date
- What you decided (which package manager, which install method)
- Why (so you don't second-guess it later)

### Quick reference

| Software type | Where it goes | Config file to edit |
|---------------|---------------|---------------------|
| Language runtime | mise | `mise/.config/mise/config.toml` |
| CLI dev tool | Nix home-manager | `nix/.config/nix/home.nix` |
| GUI app (needs system access) | apt | `packages/apt-packages.txt` |
| GUI app (sandboxable) | Flatpak | `packages/flatpak-packages.txt` |
| System library / driver | apt | `packages/apt-packages.txt` |
| Standalone binary | curl in install.sh | `install.sh` |
| App config files | Stow | `scripts/stow-dotfiles.sh` |
| API keys / secrets | Fish env vars | `docs/SECRETS.md` (docs only) |

### Example: Adding a new tool end-to-end

Say you want to add **lazydocker** (a Docker TUI):

1. **What is it?** A CLI dev tool → use Nix
2. **Add to home.nix**:
   ```nix
   home.packages = with pkgs; [
     # ... existing packages ...
     lazydocker        # TUI for Docker
   ];
   ```
3. **Apply**: `home-manager switch --flake ~/.config/nix`
4. **Has config files?** No, skip stow step
5. **Needs secrets?** No, skip SECRETS.md
6. **Log it**: Add a row to the Decision Log below

Say you want to add **Obsidian** (note-taking app):

1. **What is it?** GUI desktop app → go to Step 2
2. **Needs system access?** Not really, it's a note editor
3. **Has a Flatpak?** Yes, `md.obsidian.Obsidian` on Flathub
4. **Add to flatpak list**: `packages/flatpak-packages.txt`
5. **Apply**: `./install.sh flatpak`
6. **Has config?** Yes, but Obsidian stores vaults wherever you choose — no stow needed
7. **Needs secrets?** If using Obsidian Sync, document in SECRETS.md
8. **Log it**: Add a row to the Decision Log

---

## Decision Log

| Date | Decision | Reason |
|------|----------|--------|
| 2026-04-19 | Use mise for Node.js, Python, Elixir, Zig | Nix's read-only store breaks npm global installs and requires custom workarounds for Node path resolution |
| 2026-04-19 | Keep rustup in Nix, not mise | Rust toolchain mgmt (stable/nightly/components) is tightly coupled to rustup; mise just wraps it |
| 2026-04-19 | Remove lua from home.nix | Neovim bundles LuaJIT; standalone lua was unused |
| 2026-04-19 | Firefox via Flatpak, not apt | Mozilla maintains the Flatpak; it gets updates faster and is sandboxed |
| 2026-04-19 | WezTerm via Nix, not Flatpak | Already declared in home.nix; Nix version integrates better with Nix-managed shell |
| 2026-04-19 | GIMP via apt | Simple, well-supported on Ubuntu-based distros, no sandboxing issues |
| 2026-04-19 | VS Code via apt, not Flatpak | Flatpak VS Code has terminal/extension sandboxing issues |
| 2026-04-19 | fzf + ripgrep via Nix only | Were duplicated in both apt and Nix; consolidated to Nix for newer versions |
| 2026-04-19 | Use GNU Stow for symlinks | Simple, well-understood, no dependencies beyond the stow binary |
| 2026-04-19 | Nix with flakes + home-manager | Declarative, reproducible, pins exact package versions via flake.lock |
| 2026-04-19 | OpenCode via curl installer, not Homebrew | Dropping Homebrew as a dependency; curl script has no deps and works before Node/mise are set up |
| 2026-04-19 | Remove Homebrew from setup | Was an untracked dependency; everything it provided is now covered by apt, Nix, or curl installs |
| 2026-04-19 | Docker via apt (official Docker repo) | Docker needs system-level access (daemon, kernel features); apt with official repo gives latest stable |
| 2026-04-19 | httpie + shellcheck via Nix | CLI dev tools belong in Nix; httpie for API testing, shellcheck for linting bash scripts |
| 2026-04-19 | Broadened distro support to Ubuntu-based | Config is not Pop!_OS-specific; works on any Ubuntu-based distro |
| 2026-04-19 | Fonts installed via script, not Nix | Nix font packages can have path issues on non-NixOS; direct download to ~/.local/share/fonts is simpler and universal |
| 2026-04-19 | WezTerm shell path uses $SHELL env var | Was hardcoded to Homebrew fish path; now works regardless of how Fish is installed |
| 2026-04-19 | Docker setup uses DEB822 format + codename fallback | Matches latest Docker docs (2026-04-19); uses `${UBUNTU_CODENAME:-$VERSION_CODENAME}` for Pop!_OS compatibility |
| 2026-04-19 | Neovim via GitHub release tarball, not PPA or Nix | PPA lags weeks behind releases (0.12.0 vs 0.12.1); tarball always gives latest stable; installs to ~/.local/ |
| 2026-04-19 | Removed Zoom from apt install | Not needed by default; can be added back manually later |
| 2026-04-19 | Removed Proton Mail from apt install | Not needed by default; Proton VPN kept |
| 2026-04-19 | Added Erlang/Python build deps to apt | mise compiles runtimes from source; without libssl-dev, libncurses-dev, etc., builds fail with cryptic errors |
| 2026-04-19 | nix.conf managed via stow, not created by script | Avoids conflict between stow-managed ~/.config/nix/ and script writing nix.conf into it |
| 2026-04-19 | WezTerm keybindings use bash -c explicitly | lazygit/opencode spawns use `read -p` (bash syntax); Fish uses `read -P` — using bash avoids the incompatibility |
| 2026-04-19 | Added ubuntu-restricted-extras to apt | Media codecs for full audio/video playback support |
