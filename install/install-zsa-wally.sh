#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/lib/common.sh"

UDEV_RULES_FILE="/etc/udev/rules.d/50-zsa.rules"
UDEV_RULES_CONTENT='# Rules for Oryx web flashing and live training
KERNEL=="hidraw*", ATTRS{idVendor}=="16c0", MODE="0664", GROUP="plugdev"
KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

# Legacy rules for live training over webusb (Not needed for firmware v21+)
  # Rule for all ZSA keyboards
  SUBSYSTEM=="usb", ATTR{idVendor}=="3297", GROUP="plugdev"
  # Rule for the Moonlander
  SUBSYSTEM=="usb", ATTR{idVendor}=="3297", ATTR{idProduct}=="1969", GROUP="plugdev"
  # Rule for the Ergodox EZ
  SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="1307", GROUP="plugdev"
  # Rule for the Planck EZ
  SUBSYSTEM=="usb", ATTR{idVendor}=="feed", ATTR{idProduct}=="6060", GROUP="plugdev"

# Wally Flashing rules for the Ergodox EZ
ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"

# Keymapp / Wally Flashing rules for the Moonlander and Planck EZ
SUBSYSTEMS=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE:="0666", SYMLINK+="stm32_dfu"
# Keymapp Flashing rules for the Voyager
SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu", GROUP="plugdev"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE="0666", GROUP="plugdev"
'

require_command sudo

# 1. Verify required dependencies are installed
log "Checking required dependencies"
MISSING=()
for pkg in libusb-1.0-0 libwebkit2gtk-4.1-0; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    MISSING+=("$pkg")
  fi
done

# Ubuntu 24.04+ renamed libgtk-3-0 to libgtk-3-0t64
if ! dpkg -s "libgtk-3-0" >/dev/null 2>&1 && ! dpkg -s "libgtk-3-0t64" >/dev/null 2>&1; then
  MISSING+=("libgtk-3-0")
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  warn "Missing dependencies: ${MISSING[*]}"
  warn "Run './install.sh apt' first to install them"
  exit 1
fi
log "All dependencies are installed"

# 2. Create udev rules file
if [[ -f "$UDEV_RULES_FILE" ]]; then
  log "udev rules file already exists at $UDEV_RULES_FILE (skipping)"
else
  log "Creating udev rules file at $UDEV_RULES_FILE"
  echo "$UDEV_RULES_CONTENT" | sudo tee "$UDEV_RULES_FILE" >/dev/null
  log "udev rules file created"
fi

# 3. Ensure plugdev group exists and user is a member
log "Checking plugdev group membership"
if ! getent group plugdev >/dev/null 2>&1; then
  log "Creating plugdev group"
  sudo groupadd plugdev
fi

if id -nG "$USER" | grep -qw plugdev; then
  log "User $USER is already in the plugdev group"
else
  log "Adding $USER to plugdev group"
  sudo usermod -aG plugdev "$USER"
fi

# 4. Reload udev rules
log "Reloading udev rules"
sudo udevadm control --reload-rules
sudo udevadm trigger

log "ZSA keyboard environment setup complete"

echo
echo "============================================================"
echo " Next steps: download your flashing tool"
echo "============================================================"
echo
echo "  Keymapp (GUI - recommended):"
echo "    https://oryx.nyc3.cdn.digitaloceanspaces.com/keymapp/keymapp-latest.tar.gz"
echo "    tar -xzf keymapp-latest.tar.gz"
echo "    chmod +x keymapp && ./keymapp"
echo
echo "  Wally (CLI alternative):"
echo "    https://configure.ergodox-ez.com/wally/linux"
echo "    chmod +x wally && ./wally"
echo
echo "  IMPORTANT: Log out and back in (or reboot) so the"
echo "  plugdev group membership takes effect."
echo "============================================================"
echo
