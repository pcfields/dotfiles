#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

PACKAGES_FILE="$(packages_file apt-packages.txt)"
mapfile -t PACKAGES < <(read_package_file "$PACKAGES_FILE")

require_command sudo
require_command curl
require_command gpg
require_command dpkg

log "Adding third-party apt repositories"

sudo install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
  log "Adding VS Code repository"
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/vivaldi.list ]]; then
  log "Adding Vivaldi repository"
  curl -fsSL https://repo.vivaldi.com/archive/linux_signing_key.pub \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/vivaldi-browser.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=amd64] https://repo.vivaldi.com/archive/deb/ stable main" \
    | sudo tee /etc/apt/sources.list.d/vivaldi.list >/dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/slack.list ]]; then
  log "Adding Slack repository"
  curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/slack-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg arch=amd64] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" \
    | sudo tee /etc/apt/sources.list.d/slack.list >/dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/mise.list ]]; then
  log "Adding mise repository"
  curl -fsSL https://mise.jdx.dev/gpg-key.pub \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/mise-archive-keyring.gpg >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/mise.list >/dev/null
fi

if [[ ! -f /etc/apt/sources.list.d/wezterm.list ]]; then
  log "Adding Wezterm repository"
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  echo "deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *" \
    | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
  sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
fi

if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
  log "Adding Docker repository"
  sudo apt remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc 2>/dev/null || true
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  DOCKER_CODENAME="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
  DOCKER_ARCH="$(dpkg --print-architecture)"

  echo "deb [arch=${DOCKER_ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${DOCKER_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
fi

log "Updating apt package lists"
sudo apt update

log "Installing apt packages from $PACKAGES_FILE"
if sudo apt install -y "${PACKAGES[@]}"; then
  log "All packages installed successfully"
else
  warn "Some packages failed - re-run to retry"
fi

if command -v docker >/dev/null 2>&1; then
  if getent group docker | grep -q "$USER" 2>/dev/null; then
    log "User $USER is in docker group"
  else
    log "Adding $USER to docker group"
    sudo groupadd -f docker
    sudo usermod -aG docker "$USER"
    warn "Log out and back in before using docker without sudo"
  fi
fi

log "APT install complete"
