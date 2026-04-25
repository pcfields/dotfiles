#!/usr/bin/env bash
# ── Stow Dotfiles ───────────────────────────────────────────────────
# Uses GNU Stow to symlink config directories from ~/dotfiles into $HOME.
#
# Each top-level directory is a "stow package". For example:
#   dotfiles/nvim/.config/nvim/init.lua  →  ~/.config/nvim/init.lua
#   dotfiles/nix/.config/nix/flake.nix   →  ~/.config/nix/flake.nix
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# ── Stow packages to link ───────────────────────────────────────────
# Add new directories here as you add more configs to dotfiles
STOW_PACKAGES=(
  nvim
  ohmyposh
  wezterm
  nix
  mise
)

# ── Ensure stow is installed ────────────────────────────────────────
if ! command -v stow &>/dev/null; then
  echo "ERROR: stow is not installed. Run apt-install.sh first."
  exit 1
fi

echo "==> Stowing dotfiles from $DOTFILES_DIR..."

for pkg in "${STOW_PACKAGES[@]}"; do
  pkg_dir="$DOTFILES_DIR/$pkg"
  if [[ -d "$pkg_dir" ]]; then
    echo "  -> Stowing $pkg..."
    stow -d "$DOTFILES_DIR" -t "$HOME" --restow "$pkg"
  else
    echo "  !! Skipping $pkg (directory not found)"
  fi
done

echo "==> Stow complete!"
