#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$ROOT_DIR/install"
STATE_FILE="$ROOT_DIR/.install-state"

load_state() {
  if [[ -f "$STATE_FILE" ]]; then
    mapfile -t COMPLETED < "$STATE_FILE"
  else
    COMPLETED=()
  fi
}

save_state() {
  printf '%s\n' "${STEPS[@]}" > "$STATE_FILE"
}

is_completed() {
  local step="$1"
  [[ " ${COMPLETED[*]} " =~ " $step " ]]
}

mark_completed() {
  local step="$1"
  if ! is_completed "$step"; then
    COMPLETED+=("$step")
    save_state
  fi
}

STEPS=(
  apt
  stow
  fish
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
    fish)     echo "$INSTALL_DIR/install-fish.sh" ;;
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
  ./install.sh                Run the full install flow (resumes if interrupted)
  ./install.sh all            Run the full install flow
  ./install.sh <step>         Run a single install step
  ./install.sh reset          Clear state and start fresh

Steps:
  apt         System packages and apt repositories
  stow        Symlink configs into $HOME
  fish        Install Fish shell
  fonts       Install user fonts
  ohmyposh   Install Oh My Posh prompt engine
  rustup     Install Rustup toolchain
  nix        Install Nix and run Home Manager (requires shell restart)
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

  if is_completed "$step"; then
    echo "============================================================"
    echo "Step already completed: $step (skipping)"
    echo "============================================================"
    return 0
  fi

  echo "============================================================"
  echo "Running step: $step"
  echo "Script: $script"
  echo "============================================================"
  bash "$script"
  mark_completed "$step"
  echo
}

main() {
  local target="${1:-all}"

  load_state
  print_header

  case "$target" in
    all)
      for step in "${STEPS[@]}"; do
        run_step "$step"
      done
      ;;
    reset)
      if [[ -f "$STATE_FILE" ]]; then
        rm "$STATE_FILE"
        echo "Install state cleared"
      else
        echo "No state file to clear"
      fi
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
