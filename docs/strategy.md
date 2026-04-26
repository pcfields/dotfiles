# Dotfiles Strategy & Philosophy

> This document explains the reasoning behind the major decisions in this dotfiles
> setup. It exists because full OS rebuilds happen rarely and the details are
> easy to forget.

## Overview

This dotfiles repo manages a full development environment for Ubuntu-based Linux
systems, mainly Pop!_OS, using four package managers with distinct roles.

**Each tool has one job. Avoid overlapping responsibilities.**

```text
install.sh
  apt → fish → stow → fonts → ohmyposh → rustup → nix/home-manager → flatpak → mise-runtimes → opencode
```

## Package managers

### APT

Use apt for system libraries, drivers, build tools, desktop apps that need deep
OS integration, and anything required before Nix is installed.

Examples: `build-essential`, `cmake`, `git`, `curl`, `stow`, `code`,
`slack-desktop`, `vivaldi-stable`, `ffmpeg`, `gnome-tweaks`.

Config file: `packages/apt-packages.txt`

### Nix + Home Manager

Use Nix and Home Manager for CLI dev tools where you want latest versions,
especially the editor (Neovim).

Examples: `ripgrep`, `fd`, `bat`, `eza`, `neovim`.

Config files:
- `nix/.config/nix/flake.nix`
- `nix/.config/nix/home.nix`

### Flatpak

Use Flatpak for sandboxed GUI apps that are better maintained there and do not
need tight system integration.

Examples: Firefox, OBS Studio, Inkscape.

Config file: `packages/flatpak-packages.txt`

### mise

Use mise for programming language runtimes that need version switching between
projects.

Examples: Node.js, Python, Erlang, Elixir, Zig.

Config file: `mise/.config/mise/config.toml`

## Directory structure

```text
~/dotfiles/
├── install.sh
├── install/
│   ├── install-apt.sh
│   ├── stow-dotfiles.sh
│   ├── install-fonts.sh
│   ├── install-nix.sh
│   ├── install-flatpak.sh
│   ├── install-mise.sh
│   └── install-opencode.sh
├── lib/
│   └── common.sh
├── packages/
│   ├── apt-packages.txt
│   └── flatpak-packages.txt
├── docs/
├── nix/.config/nix/
├── mise/.config/mise/
├── nvim/.config/nvim/
├── ohmyposh/.config/ohmyposh/
├── wezterm/
└── windows/
```

## Stow model

GNU Stow creates symlinks from each top-level config directory into `$HOME`.
The directory structure inside each package mirrors the target location in the
home directory.

```text
nvim/.config/nvim/init.lua           → ~/.config/nvim/init.lua
nix/.config/nix/flake.nix            → ~/.config/nix/flake.nix
mise/.config/mise/config.toml        → ~/.config/mise/config.toml
opencode/.config/opencode/opencode.json  → ~/.config/opencode/opencode.json
```

To add a new config package:

1. Create the directory structure, for example `myapp/.config/myapp/`.
2. Add the config files.
3. Add `myapp` to `STOW_PACKAGES` in `install/stow-dotfiles.sh`.
4. Run `./install.sh stow`.

## Install order

```text
1. apt         — System packages, apt repos, Docker.
2. fish        — Install Fish shell from PPA.
3. stow        — Symlink configs into $HOME.
4. fonts       — Install user fonts.
5. ohmyposh    — Install Oh My Posh (curl script).
6. rustup      — Install Rustup (official installer).
7. nix         — Install Nix and run Home Manager (requires shell restart).
8. flatpak     — Install sandboxed GUI apps.
9. mise-runtimes — Install language runtimes.
10. opencode    — Install the OpenCode binary.
```

This order matters because each later step depends on tools or config provided
by earlier steps.

## How to run

### Full install

```bash
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Individual steps

```bash
./install.sh apt
./install.sh stow
./install.sh fonts
./install.sh ohmyposh
./install.sh rustup
./install.sh nix
./install.sh flatpak
./install.sh mise-runtimes
./install.sh opencode
```

## Day-to-day changes

| Task | Command |
|------|---------|
| Add an apt package | Add to `packages/apt-packages.txt`, run `./install.sh apt` |
| Add a Flatpak app | Add to `packages/flatpak-packages.txt`, run `./install.sh flatpak` |
| Add a CLI tool via Nix | Edit `nix/.config/nix/home.nix`, run `home-manager switch --flake ~/.config/nix` |
| Change a language version | Edit `mise/.config/mise/config.toml`, run `mise install` |
| Add a new dotfile config | Add a new package and run `./install.sh stow` |
| Update Nix packages | `cd ~/.config/nix && nix flake update && home-manager switch --flake .` |

## Notes

- The SSH key creation and clone process is documented in `docs/install.md` and
  intentionally sits outside the main install chain.
- Windows setup should live separately under `windows/` rather than mixing with
  Linux install scripts.
