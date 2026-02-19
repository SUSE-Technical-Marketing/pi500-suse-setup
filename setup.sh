#!/bin/bash

# ==============================================================================
# RASPBERRY PI 500+ :: OPENSUSE-LIKE GNOME INSTALLER
# Target OS: Raspberry Pi OS (Debian 13 Trixie)
# ==============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}[+] Starting Setup for Pi 500+ (Trixie Edition)...${NC}"

# 1. SYSTEM UPDATE
echo -e "${GREEN}[+] Updating Repositories...${NC}"
sudo apt update && sudo apt full-upgrade -y

# 2. INSTALL GNOME DESKTOP
# We install gnome-core for a lighter base, or task-gnome-desktop for the full suite.
# Given the Pi 500+ 16GB RAM, we go with the full standard experience.
echo -e "${GREEN}[+] Installing GNOME Desktop... (This may take a while)${NC}"
sudo apt install -y task-gnome-desktop gnome-tweaks gnome-shell-extensions

# 3. INSTALL THEMING ASSETS (Adwaita & Papirus)
# openSUSE uses a distinct green look. We will use Papirus-Green icons 
# which closely match the polished SUSE aesthetic.
echo -e "${GREEN}[+] Installing Theme Assets...${NC}"
sudo apt install -y papirus-icon-theme fonts-cantarell

# 4. DOWNLOAD OPENSUSE WALLPAPER
# We fetch a high-quality openSUSE wallpaper to the Pictures folder
echo -e "${GREEN}[+] Fetching openSUSE Wallpaper...${NC}"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLPAPER_DIR"
# Using a reliable raw link to a classic SUSE geometric wallpaper
wget -O "$WALLPAPER_DIR/opensuse-bg.jpg" "https://raw.githubusercontent.com/openSUSE/branding/master/wallpapers/default-1920x1080.jpg"

# 5. APPLY CONFIGURATIONS (GSETTINGS)
# This must be run as the user, not sudo, hence the lack of sudo here.
echo -e "${GREEN}[+] Applying GNOME Settings (Skinning)...${NC}"

# Set Icon Theme to Papirus (Green folders look very SUSE)
gsettings set org.gnome.desktop.interface icon-theme 'Papirus'

# Set Font (OpenSUSE often uses Cantarell or Noto Sans)
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'

# Set Wallpaper
gsettings set org.gnome.desktop.background picture-uri "file://$WALLPAPER_DIR/opensuse-bg.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALLPAPER_DIR/opensuse-bg.jpg"

# Enable Dark Mode (Modern openSUSE defaults are often dark/sleek)
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# Set Accent Color (GNOME 46/47+ feature)
# Note: Trixie likely has a newer GNOME. If 'accent-color' key exists, we set it to green.
if gsettings list-keys org.gnome.desktop.interface | grep -q "accent-color"; then
    gsettings set org.gnome.desktop.interface accent-color 'green'
fi

# 6. OPTIONAL: REMOVE RASPBERRY PI PIXEL DESKTOP (Cleanup)
# Uncomment the lines below if you want to purge the old desktop to save space.
# echo -e "${GREEN}[+] Removing default Raspberry Pi Desktop components...${NC}"
# sudo apt purge -y raspberrypi-ui-mods lxplug-* openbox
# sudo apt autoremove -y

# 7. SET DEFAULT BOOT TARGET
echo -e "${GREEN}[+] Setting Graphical Boot Target...${NC}"
sudo systemctl set-default graphical.target

echo -e "${GREEN}[+] INSTALLATION COMPLETE!${NC}"
echo "Please reboot your Pi 500+ to enter your new openSUSE-styled GNOME desktop."
echo "Type 'sudo reboot' to restart now."