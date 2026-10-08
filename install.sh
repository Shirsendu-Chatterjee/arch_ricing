#!/bin/bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages..."
sudo pacman -S --needed - < "$REPO_DIR/packages.txt"

echo "==> Installing user configuration..."

cp -a "$REPO_DIR/dotfiles/.config/." "$HOME/.config/"

echo "==> Installing SDDM theme..."

sudo mkdir -p /usr/share/sddm/themes/liquidglass
sudo cp -a "$REPO_DIR/sddm/liquidglass/." \
    /usr/share/sddm/themes/liquidglass/

echo "==> Installing SDDM configuration..."

sudo mkdir -p /etc/sddm.conf.d
sudo cp "$REPO_DIR/sddm/theme.conf" \
    /etc/sddm.conf.d/theme.conf

echo
echo "Setup restored successfully."
echo "Log out and back in for all desktop changes to take effect."
