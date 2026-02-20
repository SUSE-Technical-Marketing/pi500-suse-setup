#!/bin/bash

# ==============================================================================
# RASPBERRY PI 500+ :: OPENSUSE-LIKE GNOME INSTALLER
# Target OS: Raspberry Pi OS (Debian 13 Trixie)
# Description: Installs GNOME, deploys pre-compiled openSUSE Skeuos themes,
#              configures GTK4, Flatpak, StreamController, Plymouth, GDM3,
#              and sets the Pi 500+ keyboard to a breathing green backlight.
# ==============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

# --- Visual Output Formatting ---
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
TOTAL_STEPS=11

# Get the absolute directory of where this script is running from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}   Starting openSUSE Workstation Setup for Pi 500+    ${NC}"
echo -e "${GREEN}======================================================${NC}"

# 1. SYSTEM UPDATE
echo -e "\n${BLUE}[1/$TOTAL_STEPS] Updating System Repositories and Packages...${NC}"
sudo apt update && sudo apt full-upgrade -y

# 2. INSTALL REQUIRED PACKAGES
echo -e "\n${BLUE}[2/$TOTAL_STEPS] Installing GNOME Desktop and Core Utilities...${NC}"
sudo apt install -y task-gnome-desktop gnome-tweaks gnome-shell-extensions \
                    papirus-icon-theme fonts-cantarell \
                    plymouth plymouth-themes git

# 3. CONFIGURE FLATPAK & INSTALL APPS
echo -e "\n${BLUE}[3/$TOTAL_STEPS] Setting up Flatpak and installing StreamController...${NC}"
sudo apt install -y flatpak gnome-software-plugin-flatpak
# Add the Flathub repository if it doesn't already exist
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Install StreamController
echo -e "${YELLOW}>> Installing com.sore447.StreamController...${NC}"
sudo flatpak install -y flathub com.sore447.StreamController

# 4. DEPLOY LOCAL THEMES
echo -e "\n${BLUE}[4/$TOTAL_STEPS] Deploying Pre-compiled openSUSE Themes...${NC}"
mkdir -p ~/.themes
mkdir -p ~/.icons

if [ -d "$SCRIPT_DIR/assets/suse-theme" ]; then
    cp -r "$SCRIPT_DIR/assets/suse-theme"/* ~/.themes/
    echo -e "${YELLOW}>> Custom Skeuos themes copied successfully.${NC}"
else
    echo -e "${YELLOW}>> WARNING: assets/suse-theme directory not found! Ensure it is in your git repo.${NC}"
fi

# 5. FETCH OFFICIAL OPENSUSE WALLPAPERS
echo -e "\n${BLUE}[5/$TOTAL_STEPS] Fetching Official openSUSE Wallpapers...${NC}"
WALLPAPER_DIR="$HOME/Pictures/openSUSE-Wallpapers"
if [ ! -d "$WALLPAPER_DIR" ]; then
    git clone https://github.com/openSUSE/wallpapers.git "$WALLPAPER_DIR"
else
    echo -e "${YELLOW}>> Wallpapers already exist, pulling latest changes...${NC}"
    cd "$WALLPAPER_DIR" && git pull && cd - > /dev/null
fi

# 6. CONFIGURE GNOME & GTK4
echo -e "\n${BLUE}[6/$TOTAL_STEPS] Applying GNOME Settings & Linking GTK4...${NC}"

gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Skeuos-openSUSE-Dark'

# Handle the custom Hyprland Wallpaper
TARGET_BG="$HOME/Pictures/hyprland-opensuse.png"
if [ -f "$SCRIPT_DIR/assets/hyprland-opensuse.png" ]; then
    echo -e "${YELLOW}>> Found custom wallpaper in assets. Applying it...${NC}"
    cp "$SCRIPT_DIR/assets/hyprland-opensuse.png" "$TARGET_BG"
    gsettings set org.gnome.desktop.background picture-uri "file://$TARGET_BG"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$TARGET_BG"
else
    echo -e "${YELLOW}>> WARNING: $SCRIPT_DIR/assets/hyprland-opensuse.png not found. Using default.${NC}"
fi

echo -e "${YELLOW}>> Forcing Libadwaita (GTK4) apps to use the openSUSE theme...${NC}"
mkdir -p ~/.config/gtk-4.0
rm -rf ~/.config/gtk-4.0/{assets,gtk.css,gtk-dark.css}
ln -sf ~/.themes/Skeuos-openSUSE-Dark/gtk-4.0/assets ~/.config/gtk-4.0/assets
ln -sf ~/.themes/Skeuos-openSUSE-Dark/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css
ln -sf ~/.themes/Skeuos-openSUSE-Dark/gtk-4.0/gtk-dark.css ~/.config/gtk-4.0/gtk-dark.css

# 7. CONFIGURE TERMINAL PROMPT
echo -e "\n${BLUE}[7/$TOTAL_STEPS] Applying openSUSE Terminal Styling...${NC}"
if ! grep -q "1;32m" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# openSUSE-style terminal prompt' >> ~/.bashrc
    echo 'export PS1="\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ "' >> ~/.bashrc
    echo -e "${YELLOW}>> Prompt added to .bashrc${NC}"
fi

# 8. CONFIGURE PLYMOUTH BOOT SPLASH
echo -e "\n${BLUE}[8/$TOTAL_STEPS] Installing openSUSE Boot Splash Screen...${NC}"
PLYMOUTH_TEMP="/tmp/plymouth-opensuse"
if [ ! -d "/usr/share/plymouth/themes/opensuse-logo" ]; then
    echo -e "${YELLOW}>> Downloading Plymouth theme...${NC}"
    rm -rf "$PLYMOUTH_TEMP"
    git clone https://github.com/serhiyguryev/plymouth-theme-opensuse.git "$PLYMOUTH_TEMP"
    sudo cp -rv "$PLYMOUTH_TEMP/opensuse-logo" /usr/share/plymouth/themes/
fi

echo -e "${YELLOW}>> Rebuilding boot files (initramfs). This takes a moment...${NC}"
sudo plymouth-set-default-theme -R opensuse-logo

if ! grep -q "splash" /boot/firmware/cmdline.txt; then
    echo -e "${YELLOW}>> Adding 'splash' to /boot/firmware/cmdline.txt...${NC}"
    sudo sed -i 's/$/ quiet splash/' /boot/firmware/cmdline.txt
fi

# 9. CONFIGURE LOGIN SCREEN (GDM3)
echo -e "\n${BLUE}[9/$TOTAL_STEPS] Customizing GDM Login Screen...${NC}"
sudo sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="openSUSE Tumbleweed"/' /etc/os-release || true
sudo sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="openSUSE Tumbleweed"/' /usr/lib/os-release || true
sudo wget -qO /usr/share/pixmaps/opensuse-logo.svg https://raw.githubusercontent.com/openSUSE/branding/master/logos/geeko/geeko-color.svg || true

GDM_CONF="/etc/gdm3/greeter.dconf-defaults"
if [ -d "/etc/gdm3" ]; then
    sudo touch "$GDM_CONF"
    if ! grep -q "opensuse-logo.svg" "$GDM_CONF"; then
        echo -e "${YELLOW}>> Injecting Geeko logo into GDM3...${NC}"
        echo "" | sudo tee -a "$GDM_CONF" > /dev/null
        echo "[org/gnome/login-screen]" | sudo tee -a "$GDM_CONF" > /dev/null
        echo "logo='/usr/share/pixmaps/opensuse-logo.svg'" | sudo tee -a "$GDM_CONF" > /dev/null
    fi
fi

# 10. CONFIGURE KEYBOARD BACKLIGHT
echo -e "\n${BLUE}[10/$TOTAL_STEPS] Setting Pi 500+ Keyboard Backlight...${NC}"
if command -v rpi-keyboard-config >/dev/null 2>&1; then
    echo -e "${YELLOW}>> Setting to SUSE Green (Breathing)...${NC}"
    # Adding || true so it doesn't halt the script if it requires sudo or fails
    rpi-keyboard-config preset set 0 "Breathing" --hue 89 --sat 255 --speed 100 || true
else
    echo -e "${YELLOW}>> WARNING: rpi-keyboard-config tool not found. Skipping...${NC}"
fi

# 11. SET BOOT TARGET
echo -e "\n${BLUE}[11/$TOTAL_STEPS] Setting Default Boot Target...${NC}"
sudo systemctl set-default graphical.target || true

# --- FINISH ---
echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN} [+] INSTALLATION COMPLETE!                           ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo "Please reboot your Pi to load into your fully configured openSUSE environment."