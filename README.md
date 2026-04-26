# Dotfiles

Personal dotfiles and machine setup for Ubuntu-based Linux systems, mainly Pop!_OS.

This repository is used to rebuild a development environment after a clean install and to keep terminal, editor, shell, and tool configuration under version control.

## Start here

Read these documents in order:

1. [`docs/install.md`](docs/install.md) — first-boot prerequisites, GitHub SSH setup, and cloning the repo.
2. [`docs/secrets.md`](docs/secrets.md) — secrets, API keys, git identity, and backup checklist.
3. [`docs/strategy.md`](docs/strategy.md) — package-manager philosophy, install order, and decision framework.
4. [`docs/terminal.md`](docs/terminal.md) — terminal, prompt, and shell-specific setup notes.

## Fresh install flow

After installing Pop!_OS:

1. Follow [`docs/install.md`](docs/install.md) to get online, access email and the password manager, create an SSH key, add it to GitHub, and clone this repo.
2. Change into the repo directory.
3. Run the main installer.

```bash
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## Install steps

The installer runs the setup in stages so the machine can be rebuilt in a predictable order.

```text
apt → fish → stow → fonts → nix → flatpak → mise → opencode
```

For the reasoning behind that order, see [`docs/strategy.md`](docs/strategy.md).

### Run individual steps

```bash
./install.sh apt
./install.sh fish
./install.sh stow
./install.sh fonts
./install.sh nix
./install.sh flatpak
./install.sh mise
./install.sh opencode
```

## Common tasks

| Task | Action |
|------|--------|
| Add an apt package | Edit `packages/apt-packages.txt`, then run `./install.sh apt` |
| Add a Flatpak app | Edit `packages/flatpak-packages.txt`, then run `./install.sh flatpak` |
| Add a CLI tool via Nix | Edit `nix/.config/nix/home.nix`, then run `home-manager switch --flake ~/.config/nix` |
| Change runtime versions | Edit `mise/.config/mise/config.toml`, then run `mise install` |
| Add a new dotfile config | Add a new stow package and run `./install.sh stow` |
| Install OpenCode only | Run `./install.sh opencode` |

## Repository layout

```text
.
├── docs/                      # Install guide, secrets, strategy, terminal notes
├── install/                   # Ordered install scripts
├── lib/                       # Shared shell helpers
├── install.sh                 # Main installer entry point
├── packages/                  # apt and Flatpak package lists
├── nix/.config/nix/           # Nix + Home Manager config
├── mise/.config/mise/         # Runtime versions
├── nvim/.config/nvim/         # Neovim config
├── ohmyposh/.config/ohmyposh/ # Prompt config
├── opencode/.config/opencode/ # OpenCode config (stow-managed)
├── wezterm/                   # WezTerm config
└── windows/                   # Windows-specific setup scripts
```

## Notes

- Secrets and credentials are not stored in this repo. See [`docs/secrets.md`](docs/secrets.md).
- The SSH key creation and clone flow is intentionally documented in `docs/install.md` instead of being part of `install.sh`.
- OpenCode config should live in `opencode/.config/opencode/` and be linked into `~/.config/opencode` via the stow step.
- OpenCode provider authentication should still be configured manually after install.
- This setup is mainly for Pop!_OS, but most of it should work on other Ubuntu-based systems.
