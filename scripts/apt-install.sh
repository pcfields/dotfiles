#!/usr/bin/env bash
# ── Install APT Packages ────────────────────────────────────────────
# Adds third-party repositories, then installs packages from apt-packages.txt
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$DOTFILES_DIR/packages/apt-packages.txt"

if [[ ! -f "$PACKAGES_FILE" ]]; then
  echo "ERROR: $PACKAGES_FILE not found"
  exit 1
fi

echo "==> Adding third-party repositories..."

# ── VS Code ──────────────────────────────────────────────────────────
if ! apt-cache policy 2>/dev/null | grep -q "packages.microsoft.com/repos/code"; then
  echo "  -> Adding VS Code repo..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg
  sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
  rm -f /tmp/packages.microsoft.gpg
fi

# ── Vivaldi ──────────────────────────────────────────────────────────
if ! apt-cache policy 2>/dev/null | grep -q "vivaldi"; then
  echo "  -> Adding Vivaldi repo..."
  wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | \
    sudo tee /usr/share/keyrings/vivaldi-browser.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=amd64] https://repo.vivaldi.com/archive/deb/ stable main" | \
    sudo tee /etc/apt/sources.list.d/vivaldi.list > /dev/null
fi

# ── Slack ─────────────────────────────────────────────────────────────
if ! apt-cache policy 2>/dev/null | grep -q "slack"; then
  echo "  -> Adding Slack repo..."
  wget -qO- https://packagecloud.io/slacktechnologies/slack/gpgkey | gpg --dearmor | \
    sudo tee /usr/share/keyrings/slack-archive-keyring.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg arch=amd64] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" | \
    sudo tee /etc/apt/sources.list.d/slack.list > /dev/null
fi

# ── mise ──────────────────────────────────────────────────────────────
if ! apt-cache policy 2>/dev/null | grep -q "mise"; then
  echo "  -> Adding mise repo..."
  wget -qO- https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | \
    sudo tee /usr/share/keyrings/mise-archive-keyring.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | \
    sudo tee /etc/apt/sources.list.d/mise.list > /dev/null
fi

# ── Proton VPN ────────────────────────────────────────────────────────
# protonvpn-stable-release package sets up the repo itself
# It needs to be installed first, then apt update, then install the client

# ── Docker ────────────────────────────────────────────────────────────
# https://docs.docker.com/engine/install/ubuntu/ (checked 2026-04-19)
if ! apt-cache policy 2>/dev/null | grep -q "download.docker.com"; then
  echo "  -> Removing conflicting Docker packages (if any)..."
  sudo apt remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null || true

  echo "  -> Adding Docker repo..."
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # DEB822 format — uses UBUNTU_CODENAME with VERSION_CODENAME fallback (needed for Pop!_OS)
  sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
fi

echo "==> Updating package lists..."
sudo apt update

echo "==> Reading package list from $PACKAGES_FILE..."
PACKAGES=()
while IFS= read -r line; do
  # Skip comments and blank lines
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"
  [[ -z "$line" ]] && continue
  PACKAGES+=("$line")
done < "$PACKAGES_FILE"

echo "==> Installing ${#PACKAGES[@]} packages..."
echo "    ${PACKAGES[*]}"

# Install protonvpn-stable-release first if in the list (sets up its own repo)
if printf '%s\n' "${PACKAGES[@]}" | grep -q "^protonvpn-stable-release$"; then
  echo "  -> Installing protonvpn-stable-release (sets up Proton repo)..."
  sudo apt install -y protonvpn-stable-release 2>/dev/null || true
  sudo apt update
fi

sudo apt install -y "${PACKAGES[@]}"

echo "==> APT installation complete!"

# ── Docker post-install (add user to docker group) ────────────────────
if command -v docker &>/dev/null; then
  if ! groups "$USER" | grep -q docker; then
    echo "==> Adding $USER to docker group (avoids needing sudo for docker)..."
    sudo groupadd -f docker
    sudo usermod -aG docker "$USER"
    echo "  -> You need to log out and back in for this to take effect."
  fi
fi
