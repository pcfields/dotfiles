# Agent Instructions for Dotfiles

## Workflow

**Always ask for confirmation before making changes.** Do not assume or proceed without checking first, even if the change seems obvious.

## Install workflow

Run individual steps:
```bash
./install.sh apt       # System packages
./install.sh stow     # Symlink configs into $HOME
./install.sh fonts
./install.sh ohmyposh # Oh My Posh prompt engine
./install.sh rustup   # Rust toolchain
./install.sh nix      # May require shell restart before continuing
./install.sh flatpak
./install.sh mise-runtimes # Language runtimes
./install.sh opencode # Binary only
```

**Order matters.** Nix requires a shell restart after install but before the next step. Docker group membership requires logout/login.

## Stow model

Each top-level directory is a stow package. The internal structure mirrors the target location:

```
nvim/.config/nvim/init.lua  → ~/.config/nvim/init.lua
nix/.config/nix/home.nix    → ~/.config/nix/home.nix
```

To add a new config package:
1. Create the directory structure, e.g. `myapp/.config/myapp/`
2. Add config files
3. Add `myapp` to `STOW_PACKAGES` in `install/stow-dotfiles.sh`
4. Run `./install.sh stow`

## Package manager boundaries

| Package type | Tool | Config |
|---|---|---|
| System apps, Docker, GUI apps | apt | `packages/apt-packages.txt` |
| CLI dev tools, shell config | Nix + Home Manager | `nix/.config/nix/home.nix` |
| Sandboxed GUI apps | Flatpak | `packages/flatpak-packages.txt` |
| Language runtimes (Node, Python, etc.) | mise | `mise/.config/mise/config.toml` |

## Updating configs

```bash
# Nix/Home Manager
cd ~/.config/nix && nix flake update && home-manager switch --flake .

# mise
mise install
```

## Notes

- Secrets and API keys are NOT stored here
- nvim/ subdirectory has its own AGENTS.md for Neovim-specific guidance

## OpenCode Model Selection

Switch models in OpenCode:
```bash
/model copilot-sonnet  # Default - good balance
/model copilot-opus    # Complex refactoring
/model copilot-haiku  # Quick/simple tasks
```

API keys (set in shell):
```bash
set -Ux COPILOT_API_KEY your-key
```