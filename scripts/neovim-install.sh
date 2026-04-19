#!/usr/bin/env bash
# ── Install Neovim (latest GitHub release) ───────────────────────────
# Downloads the latest stable Neovim release tarball from GitHub and
# installs it to ~/.local/. This gives you the latest version without
# waiting for PPA updates.
#
# To update Neovim later, just re-run this script.
set -euo pipefail

INSTALL_DIR="$HOME/.local"
NVIM_BIN="$INSTALL_DIR/bin/nvim"

echo "==> Checking latest Neovim release..."
LATEST_TAG=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)

if [[ -z "$LATEST_TAG" ]]; then
  echo "ERROR: Could not determine latest Neovim version."
  exit 1
fi

echo "  -> Latest version: $LATEST_TAG"

# Check if already installed at this version
if command -v nvim &>/dev/null; then
  CURRENT_VERSION="v$(nvim --version | head -1 | grep -oP '\d+\.\d+\.\d+')"
  if [[ "$CURRENT_VERSION" == "$LATEST_TAG" ]]; then
    echo "  -> Neovim $LATEST_TAG is already installed. Skipping."
    exit 0
  fi
  echo "  -> Upgrading from $CURRENT_VERSION to $LATEST_TAG"
fi

TARBALL_URL="https://github.com/neovim/neovim/releases/download/${LATEST_TAG}/nvim-linux-x86_64.tar.gz"

echo "==> Downloading Neovim $LATEST_TAG..."
TMPDIR=$(mktemp -d)
curl -fsSL "$TARBALL_URL" -o "$TMPDIR/nvim.tar.gz"

echo "==> Extracting to $INSTALL_DIR..."
# Remove old Neovim files if present
rm -rf "$INSTALL_DIR/share/nvim" "$INSTALL_DIR/lib/nvim" "$NVIM_BIN"

# Extract — tarball contains nvim-linux-x86_64/{bin,lib,share}
tar xzf "$TMPDIR/nvim.tar.gz" -C "$TMPDIR"
mkdir -p "$INSTALL_DIR/bin" "$INSTALL_DIR/lib" "$INSTALL_DIR/share"
cp -r "$TMPDIR/nvim-linux-x86_64/bin/"* "$INSTALL_DIR/bin/"
cp -r "$TMPDIR/nvim-linux-x86_64/lib/"* "$INSTALL_DIR/lib/"
cp -r "$TMPDIR/nvim-linux-x86_64/share/"* "$INSTALL_DIR/share/"

rm -rf "$TMPDIR"

echo "==> Verifying installation..."
if "$NVIM_BIN" --version | head -1; then
  echo "==> Neovim installed successfully!"
else
  echo "ERROR: Neovim installation failed."
  exit 1
fi

# Ensure ~/.local/bin is in PATH
if ! echo "$PATH" | grep -q "$INSTALL_DIR/bin"; then
  echo ""
  echo "NOTE: Make sure ~/.local/bin is in your PATH."
  echo "  It should already be included by default on most Ubuntu-based systems."
fi
