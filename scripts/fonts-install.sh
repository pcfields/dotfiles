#!/usr/bin/env bash
# ── Install Fonts ────────────────────────────────────────────────────
# Downloads and installs fonts used by WezTerm and Oh My Posh.
# Fonts are installed to ~/.local/share/fonts/ (user-level, no sudo needed).
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# ── Monaspace (primary WezTerm font) ─────────────────────────────────
# Includes Nerd Font patched variants (MonaspaceNeonNF-*)
if ! fc-list | grep -qi "Monaspace Neon"; then
  echo "==> Installing Monaspace fonts..."
  MONASPACE_VERSION="v1.101"
  curl -fsSL "https://github.com/githubnext/monaspace/releases/download/${MONASPACE_VERSION}/monaspace-${MONASPACE_VERSION}.zip" \
    -o "$TEMP_DIR/monaspace.zip"
  unzip -qo "$TEMP_DIR/monaspace.zip" -d "$TEMP_DIR/monaspace"

  # Copy all .otf and .ttf font files
  find "$TEMP_DIR/monaspace" -type f \( -name "*.otf" -o -name "*.ttf" \) -exec cp {} "$FONT_DIR/" \;
  echo "  -> Monaspace fonts installed"
else
  echo "==> Monaspace fonts already installed, skipping..."
fi

# ── JetBrains Mono (fallback WezTerm font) ───────────────────────────
if ! fc-list | grep -qi "JetBrains Mono"; then
  echo "==> Installing JetBrains Mono..."
  JETBRAINS_VERSION="2.304"
  curl -fsSL "https://github.com/JetBrains/JetBrainsMono/releases/download/v${JETBRAINS_VERSION}/JetBrainsMono-${JETBRAINS_VERSION}.zip" \
    -o "$TEMP_DIR/jetbrainsmono.zip"
  unzip -qo "$TEMP_DIR/jetbrainsmono.zip" -d "$TEMP_DIR/jetbrainsmono"

  find "$TEMP_DIR/jetbrainsmono" -type f -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
  echo "  -> JetBrains Mono installed"
else
  echo "==> JetBrains Mono already installed, skipping..."
fi

# ── MesloLGS Nerd Font (used by Oh My Posh) ──────────────────────────
if ! fc-list | grep -qi "MesloLGS Nerd Font"; then
  echo "==> Installing MesloLGS Nerd Font..."
  MESLO_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
  curl -fsSL "${MESLO_BASE}/Meslo.zip" -o "$TEMP_DIR/meslo.zip"
  unzip -qo "$TEMP_DIR/meslo.zip" -d "$TEMP_DIR/meslo"

  find "$TEMP_DIR/meslo" -type f -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
  echo "  -> MesloLGS Nerd Font installed"
else
  echo "==> MesloLGS Nerd Font already installed, skipping..."
fi

# ── Refresh font cache ──────────────────────────────────────────────
echo "==> Refreshing font cache..."
fc-cache -fv "$FONT_DIR" > /dev/null 2>&1

echo "==> Font installation complete!"
echo "    Installed to: $FONT_DIR"
