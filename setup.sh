#!/bin/bash

# ==============================================================================
# RASPBERRY PI 500+ :: OPENSUSE-LIKE GNOME INSTALLER
# Target OS: Raspberry Pi OS (Debian 13 Trixie)
# Description: Installs GNOME, deploys pre-compiled openSUSE Skeuos themes,
#              configures GTK4, applies openSUSE wallpapers, tweaks the bash 
#              prompt, and sets up a custom Plymouth boot splash.
# ==============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

# --- Visual Output Formatting ---
GREEN='\033[1;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
TOTAL_STEPS=8

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}   Starting openSUSE Workstation Setup for Pi 500+    ${NC}"
echo -e "${GREEN}======================================================${NC}"

# 1. SYSTEM UPDATE
echo -e "\n${BLUE}[1/$TOTAL_STEPS] Updating System Repositories and Packages...${NC}"
sudo apt update && sudo apt full-upgrade -y

# 2. INSTALL REQUIRED PACKAGES
echo -e "\n${BLUE}[2/$TOTAL_STEPS] Installing GNOME Desktop and Core Utilities...${NC}"
echo -e "${YELLOW}>> This step will download several gigabytes. Grab a coffee!${NC}"
sudo apt install -y task-gnome-desktop gnome-tweaks gnome-shell-extensions \
                    papirus-icon-theme fonts-cantarell \
                    plymouth plymouth-themes git

# 3. DEPLOY LOCAL THEMES (From ./assets)
echo -e "\n${BLUE}[3/$TOTAL_STEPS] Deploying Pre-compiled openSUSE Themes...${NC}"
mkdir -p ~/.themes
mkdir -p ~/.icons

if [ -d "assets/suse-theme" ]; then
    cp -r assets/suse-theme/* ~/.themes/
    echo -e "${YELLOW}>> Custom Skeuos themes copied successfully.${NC}"
else
    echo -e "${YELLOW}>> WARNING: assets/suse-theme directory not found! Skipping...${NC}"
fi

# 4. FETCH OFFICIAL OPENSUSE WALLPAPERS
echo -e "\n${BLUE}[4/$TOTAL_STEPS] Fetching Official openSUSE Wallpapers...${NC}"
WALLPAPER_DIR="$HOME/Pictures/openSUSE-Wallpapers"
if [ ! -d "$WALLPAPER_DIR" ]; then
    git clone https://github.com/openSUSE/wallpapers.git "$WALLPAPER_DIR"
else
    echo -e "${YELLOW}>> Wallpapers already exist, pulling latest changes...${NC}"
    cd "$WALLPAPER_DIR" && git pull && cd - > /dev/null
fi

# 5. CONFIGURE GNOME & GTK4
echo -e "\n${BLUE}[5/$TOTAL_STEPS] Applying GNOME Settings & Linking GTK4...${NC}"

# Use gsettings to apply the standard GTK3/GNOME parameters
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Skeuos-openSUSE-Dark'

# Pick a specific wallpaper from the cloned repo (e.g., Leap 15.4 default)
TARGET_BG="$WALLPAPER_DIR/wallpapers/leap15.4/default-1920x1080.jpg"
if [ -f "$TARGET_BG" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$TARGET_BG"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$TARGET_BG"
fi

# Link GTK4 configuration so modern apps match the theme
echo -e "${YELLOW}>> Forcing Libadwaita (GTK4) apps to use the openSUSE theme...${NC}"
mkdir -p ~/.config/gtk-4.0
rm -rf ~/.config/gtk-4.0/{assets,gtk.css,gtk-dark.css}
ln -sf ~/.themes/Skeuos-openSUSE-Dark/gtk-4.0/assets ~/.config/gtk-4.0/assets
ln -sf ~/.themes/Skeuos-openSUSE-Dark/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css
ln -sf ~/.themes/Skeuos-openSUSE-Dark/gtk-4.0/gtk-dark.css ~/.config/gtk-4.0/gtk-dark.css

# 6. CONFIGURE TERMINAL PROMPT
echo -e "\n${BLUE}[6/$TOTAL_STEPS] Applying openSUSE Terminal Styling...${NC}"
if ! grep -q "1;32m" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# openSUSE-style terminal prompt' >> ~/.bashrc
    echo 'export PS1="\[\033[1;32m\]\u@\h\[\033[0m\]:\[\033[1;34m\]\w\[\033[0m\]\$ "' >> ~/.bashrc
    echo -e "${YELLOW}>> Prompt added to .bashrc${NC}"
else
    echo -e "${YELLOW}>> Prompt styling already present in .bashrc${NC}"
fi

# 7. CONFIGURE PLYMOUTH BOOT SPLASH
echo -e "\n${BLUE}[7/$TOTAL_STEPS] Installing openSUSE Boot Splash Screen...${NC}"
if [ -d "assets/plymouth-opensuse/opensuse-logo" ]; then
    # Copy theme to system directory
    sudo cp -rv assets/plymouth-opensuse/opensuse-logo /usr/share/plymouth/themes/
    
    # Set default theme and rebuild initramfs
    echo -e "${YELLOW}>> Rebuilding boot files (initramfs). This takes a moment...${NC}"
    sudo plymouth-set-default-theme -R opensuse-logo
    
    # Ensure 'quiet' and 'splash' are in cmdline.txt for the splash screen to actually show
    if ! grep -q "splash" /boot/firmware/cmdline.txt; then
        echo -e "${YELLOW}>> Adding 'splash' to /boot/firmware/cmdline.txt...${NC}"
        sudo sed -i 's/$/ quiet splash/' /boot/firmware/cmdline.txt
    fi
else
    echo -e "${YELLOW}>> WARNING: assets/plymouth-opensuse/opensuse-logo not found! Skipping boot splash...${NC}"
fi

# 8. SET BOOT TARGET
echo -e "\n${BLUE}[8/$TOTAL_STEPS] Setting Default Boot Target...${NC}"
sudo systemctl set-default graphical.target

# --- FINISH ---
echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN} [+] INSTALLATION COMPLETE!                           ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo "Everything from the GTK/GNOME skinning to the bootloader has been applied."
echo "Please reboot your Pi to load into your new openSUSE-styled environment."