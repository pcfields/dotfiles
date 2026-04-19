# Dotfiles

Personal dotfiles and system configuration for Pop!_OS. Manages a full
development environment using automated install scripts.

> For the full strategy and reasoning behind these decisions, see [docs/STRATEGY.md](docs/STRATEGY.md).
> For secrets, API keys, and post-install setup, see [docs/SECRETS.md](docs/SECRETS.md).

## Quick Start (Fresh Pop!_OS Install)

```bash
# 1. Install git (only thing you need manually) and clone dotfiles
sudo apt update && sudo apt install -y git
git clone https://github.com/pcfields/dotfiles.git ~/dotfiles

# 2. Run the installer
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

This runs six steps in order: **apt** → **stow** → **nix** → **flatpak** → **mise** → **opencode**

You'll be prompted for your password (sudo) during the apt and nix steps.

**After the nix step**, you may need to log out and back in for Fish shell to
take effect. The script will tell you if this is needed.

## What Gets Installed

### Via APT (system packages)
build-essential, cmake, ninja-build, git, curl, wget, stow, mise, VS Code,
Slack, Vivaldi, Zoom, Proton VPN, Proton Mail, flameshot, ksnip, gimp,
gnome-tweaks, ffmpeg, wireguard-tools

### Via Nix Home Manager (CLI tools + shell)
ripgrep, fd, fzf, bat, eza, zoxide, jq, yq, delta, lazygit, btop, htop,
oh-my-posh, rustup, Fish shell + config, git config, fzf config

### Via Flatpak (sandboxed GUI apps)
OBS Studio, Inkscape, Firefox

### Via mise (language runtimes)
Node.js 22, Python 3.12, Erlang 27, Elixir 1.17, Zig (latest)

### Via curl installer
OpenCode (AI coding agent)

## Running Individual Steps

```bash
./install.sh apt       # Only apt packages + repos
./install.sh stow      # Only symlink configs
./install.sh nix       # Only Nix + home-manager
./install.sh flatpak   # Only Flatpak apps
./install.sh mise      # Only mise runtimes
./install.sh opencode  # Only OpenCode
```

## Adding New Packages

| What | Where | Then run |
|------|-------|----------|
| System/GUI app | `packages/apt-packages.txt` | `./install.sh apt` |
| CLI dev tool | `nix/.config/nix/home.nix` | `home-manager switch --flake ~/.config/nix` |
| Sandboxed GUI app | `packages/flatpak-packages.txt` | `./install.sh flatpak` |
| Language runtime | `mise/.config/mise/config.toml` | `mise install` |
| New config files | Create `dotfiles/app/.config/app/`, add to `stow-dotfiles.sh` | `./install.sh stow` |

## Updating

```bash
# Update Nix packages
cd ~/.config/nix && nix flake update && home-manager switch --flake .

# Update mise runtimes
mise upgrade

# Update apt packages
sudo apt update && sudo apt upgrade

# Update Flatpak apps
flatpak update
```

## Structure

```
├── install.sh                # Master installer (run this)
├── docs/                     # Strategy, secrets, and decision docs
├── packages/                 # Package lists (apt, flatpak)
├── scripts/                  # Individual install scripts
├── nix/.config/nix/          # Nix flake + Home Manager config
├── mise/.config/mise/        # Language runtime versions
├── nvim/.config/nvim/        # Neovim config
├── ohmyposh/.config/ohmyposh/# Prompt theme
└── wezterm/.config/wezterm/  # Terminal config
```

## Neovim Config References

Inspired by:

- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- [nvim2k](https://github.com/2kabhishek/nvim2k)
- [josean-dev](https://github.com/josean-dev/dev-environment-files/blob/main/.config/nvim)
- [Allaman/nvim](https://github.com/Allaman/nvim/)
- [exosyphon/nvim](https://github.com/exosyphon/nvim/tree/main)
