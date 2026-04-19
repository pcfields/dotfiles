#!/usr/bin/env bash
# ── Master Install Script ───────────────────────────────────────────
# Run this on a fresh Ubuntu-based install (Pop!_OS, Ubuntu, etc.) to set up everything.
#
# Usage:
#   cd ~/dotfiles
#   ./install.sh           # Run everything
#   ./install.sh apt       # Run only apt install
#   ./install.sh nix       # Run only nix/home-manager
#   ./install.sh flatpak   # Run only flatpak install
#   ./install.sh stow      # Run only stow symlinks
#   ./install.sh mise      # Run only mise runtime install
#   ./install.sh opencode  # Run only OpenCode install
#   ./install.sh fonts     # Run only font install
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$SCRIPT_DIR/scripts"

run_apt() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 1: APT Packages"
  echo "════════════════════════════════════════════════════════════════"
  bash "$SCRIPTS/apt-install.sh"
}

run_stow() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 2: Stow Dotfiles"
  echo "════════════════════════════════════════════════════════════════"
  bash "$SCRIPTS/stow-dotfiles.sh"
}

run_nix() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 3: Nix + Home Manager"
  echo "════════════════════════════════════════════════════════════════"
  bash "$SCRIPTS/nix-install.sh"
}

run_flatpak() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 4: Flatpak Apps"
  echo "════════════════════════════════════════════════════════════════"
  bash "$SCRIPTS/flatpak-install.sh"
}

run_mise() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 5: mise Language Runtimes"
  echo "════════════════════════════════════════════════════════════════"
  if ! command -v mise &>/dev/null; then
    echo "ERROR: mise not installed. Run apt-install.sh first."
    exit 1
  fi
  echo "==> Installing mise runtimes from global config..."
  mise install --yes
  echo "==> mise runtimes installed!"
  echo ""
  echo "Installed tools:"
  mise list
}

run_opencode() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 6: OpenCode (AI coding agent)"
  echo "════════════════════════════════════════════════════════════════"
  if command -v opencode &>/dev/null; then
    echo "==> OpenCode already installed ($(opencode --version)), skipping..."
  else
    echo "==> Installing OpenCode..."
    curl -fsSL https://opencode.ai/install | bash
  fi
  echo "==> OpenCode setup complete!"
  echo ""
  echo "To configure, run 'opencode' in a project directory and use /connect"
  echo "to set up your LLM provider. See docs/SECRETS.md for details."
}

run_fonts() {
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  STEP 7: Fonts (Monaspace Neon, JetBrains Mono, MesloLGS NF)"
  echo "════════════════════════════════════════════════════════════════"
  bash "$SCRIPTS/fonts-install.sh"
}

# ── Main ─────────────────────────────────────────────────────────────
TARGET="${1:-all}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          Dotfiles Installer                                ║"
echo "║          github.com/pcfields/dotfiles                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"

  # Ensure git is available (needed to clone this repo in the first place,
  # but also needed by Nix flakes and mise)
  if ! command -v git &>/dev/null; then
    echo "==> Installing git..."
    sudo apt update && sudo apt install -y git
  fi

case "$TARGET" in
  all)
    echo ""
    echo "Running full install: apt → stow → fonts → nix → flatpak → mise → opencode"
    echo "This will take a while on a fresh system."
    echo ""
    read -rp "Press Enter to continue (Ctrl+C to abort)..."
    run_apt
    run_stow
    run_fonts
    run_nix
    run_flatpak
    run_mise
    run_opencode
    ;;
  apt)      run_apt ;;
  stow)     run_stow ;;
  fonts)    run_fonts ;;
  nix)      run_nix ;;
  flatpak)  run_flatpak ;;
  mise)     run_mise ;;
  opencode) run_opencode ;;
  *)
    echo "Usage: $0 [all|apt|stow|fonts|nix|flatpak|mise|opencode]"
    exit 1
    ;;
esac

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Done! You may need to log out and back in for all changes"
echo "  to take effect (especially shell and PATH changes)."
echo "════════════════════════════════════════════════════════════════"
