#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$ROOT_DIR/install"

STEPS=(
  apt
  stow
  fonts
  ohmyposh
  rustup
  nix
  flatpak
  mise-runtimes
  opencode
)

step_script() {
  local step="$1"
  case "$step" in
    apt)      echo "$INSTALL_DIR/install-apt.sh" ;;
    stow)     echo "$INSTALL_DIR/stow-dotfiles.sh" ;;
    fonts)    echo "$INSTALL_DIR/install-fonts.sh" ;;
    ohmyposh) echo "$INSTALL_DIR/install-ohmyposh.sh" ;;
    rustup)   echo "$INSTALL_DIR/install-rustup.sh" ;;
    nix)      echo "$INSTALL_DIR/install-nix.sh" ;;
    flatpak)  echo "$INSTALL_DIR/install-flatpak.sh" ;;
    mise-runtimes) echo "$INSTALL_DIR/install-mise-runtimes.sh" ;;
    opencode) echo "$INSTALL_DIR/install-opencode.sh" ;;
    *)        return 1 ;;
  esac
}

print_header() {
  echo
  echo "Dotfiles installer"
  echo "Repo: github.com/pcfields/dotfiles"
  echo
}

print_usage() {
  cat <<'EOF_USAGE'
Usage:
  ./install.sh                Run the full install flow
  ./install.sh all            Run the full install flow
  ./install.sh <step>         Run a single install step

Steps:
  apt         System packages and apt repositories
  stow        Symlink configs into $HOME
  fonts       Install user fonts
  ohmyposh   Install Oh My Posh prompt engine
  rustup     Install Rustup toolchain
  nix        Install Nix and run Home Manager
  flatpak    Install Flatpak apps
  mise-runtimes Install language runtimes via mise
  opencode   Install OpenCode binary
EOF_USAGE
}

run_step() {
  local step="$1"
  local script

  script="$(step_script "$step")" || {
    echo "Unknown step: $step"
    echo
    print_usage
    exit 1
  }

  if [[ ! -f "$script" ]]; then
    echo "Missing script: $script"
    exit 1
  fi

  echo "============================================================"
  echo "Running step: $step"
  echo "Script: $script"
  echo "============================================================"
  bash "$script"
  echo
}

main() {
  local target="${1:-all}"

  print_header

  case "$target" in
    all)
      for step in "${STEPS[@]}"; do
        run_step "$step"
      done
      ;;
    help|-h|--help)
      print_usage
      ;;
    *)
      run_step "$target"
      ;;
  esac

  echo "Done."
}

main "$@"
