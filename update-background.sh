#!/bin/bash

# Set directory and colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m'

background_image="S26_SafetySlide-SUSECON.png"

if [ ! -d "$SCRIPT_DIR/assets" ]; then
    echo -e "${YELLOW}⚠️  Local assets not found. Using cloned repository for assets...${NC}"
    SETUP_FOLDER="/opt/pi500-suse-setup"
    mkdir -p ${SETUP_FOLDER}
    echo -e "${YELLOW}>> Cloning asset repository...${NC}"
    GIT_REPO_NAME="pi500-suse-setup"
    GIT_REVISION=${GIT_REVISION:-'refs/heads/main'}
    GIT_VERSION="${GIT_REVISION#refs/heads/}"
    curl -fSsL -o ${GIT_REPO_NAME}.tar.gz https://github.com/SUSE-Technical-Marketing/${GIT_REPO_NAME}/archive/${GIT_REVISION}.tar.gz
    if [ $? -ne 0 ]; then
        fatal "Failed to download ${GIT_REPO_NAME} from ${GIT_REVISION}"
    fi

    tar -xzf  ${GIT_REPO_NAME}.tar.gz -C ${SETUP_FOLDER} --strip-components=1
    echo -e "${GREEN}>> Repository cloned successfully.${NC}"

    SCRIPT_DIR="$SETUP_FOLDER"
else
    echo -e "${GREEN}>> Local assets found. Update existing files...${NC}"
    curl -fSsL -o ${GIT_REPO_NAME}.tar.gz https://github.com/SUSE-Technical-Marketing/${GIT_REPO_NAME}/archive/${GIT_REVISION}.tar.gz
    if [ $? -ne 0 ]; then
        fatal "Failed to download ${GIT_REPO_NAME} from ${GIT_REVISION}"
    fi

    tar -xzf  ${GIT_REPO_NAME}.tar.gz -C ${SETUP_FOLDER} --strip-components=1
fi

ASSET_DIR="$SCRIPT_DIR/assets"

## Overwrite power settings and background configuration
rm /etc/dconf/db/local.d/01-power-settings
cat <<EOF > /etc/dconf/db/local.d/01-power-settings
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
idle-dim=false
power-button-action='interactive'

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/background]
picture-uri="file:///usr/share/backgrounds/$background_image"
picture-uri-dark="file:///usr/share/backgrounds/$background_image"
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri="file:///usr/share/backgrounds/$background_image"
EOF
dconf update

# Copy background asset to system directory
mkdir -p /usr/share/backgrounds
for img in "$ASSET_DIR"/backgrounds/*.{png,jpg,jpeg}; do
    if [ -f "$img" ]; then
        cp "$img" /usr/share/backgrounds/
        chmod 644 "/usr/share/backgrounds/$(basename "$img")"
    fi
done
