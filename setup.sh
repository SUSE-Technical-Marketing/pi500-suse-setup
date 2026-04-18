#!/bin/bash

# --- openSUSE Raspberry Pi / StreamController Setup ---
# Designed for openSUSE Tumbleweed on a Raspberry Pi (ARM64)
# Usage: curl -sL https://raw.githubusercontent.com/SUSE-Technical-Marketing/pi500-suse-setup/main/setup.sh | GIT_REVISION="refs/heads/main" sudo -E bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Set directory and colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m'

# ==============================================================================
# 0. ASSET REPO CLONE (if needed)
# ==============================================================================
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
    echo -e "${GREEN}>> Local assets found. Using existing files...${NC}"
fi

ASSET_DIR="$SCRIPT_DIR/assets"

# ==============================================================================
# 1. PACKAGE INSTALLATION (Zypper)
# ==============================================================================
echo -e "${YELLOW}>> Installing repositories and packages...${NC}"
zypper --gpg-auto-import-keys ref
zypper --gpg-auto-import-keys in -y fastfetch curl git bash-completion vim nano iputils wget \
             mc tree bat btop open-iscsi cryptsetup qemu-guest-agent flatpak openssl chromium yq
echo -e "${GREEN}>> Package installation complete.${NC}"

# ==============================================================================
# 2. USER CONFIGURATION & SUDOERS
# ==============================================================================
# Format: "username:password_hash"

echo -e "${YELLOW}>> Configuring Users and Sudo access...${NC}"
USER_YAML="$ASSET_DIR/users.yaml"
if [ ! -f "$USER_YAML" ]; then
    echo -e "${YELLOW}⚠️  users.yaml not found. Skipping user configuration...${NC}"
else
    # Ensure wheel group exists before creating users
    groupadd -f wheel

    # Iterate over users defined in users.yaml
    while IFS=: read -r USER HASH; do
        echo -e "${YELLOW}Configuring user: $USER${NC}"
        if ! id "$USER" &>/dev/null; then
            useradd -m -G wheel -s /bin/bash "$USER"
            echo "$USER:$HASH" | chpasswd -e
            # Set Passwordless Sudo
            echo "$USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER"
            chmod 440 "/etc/sudoers.d/$USER"
        fi

        mkdir -p "/home/$USER/.ssh"
        touch "/home/$USER/.ssh/authorized_keys"
        chown -R "$USER:$USER" "/home/$USER/.ssh"
        chmod 700 "/home/$USER/.ssh"

        # Add SSH keys to authorized_keys (supports both single ssh_key and ssh_keys array)
        yq e ".users[] | select(.name == \"$USER\") | .ssh_key // empty, .ssh_keys[]? // empty" "$USER_YAML" | while read -r KEY; do
            if [ -n "$KEY" ] && ! grep -qF "$KEY" "/home/$USER/.ssh/authorized_keys"; then
                echo "$KEY" >> "/home/$USER/.ssh/authorized_keys"
                echo -e "${GREEN}  Added SSH key for $USER${NC}"
            fi
        done
        chmod 600 "/home/$USER/.ssh/authorized_keys"
    done < <(yq e '.users[] | "\(.name):\(.password)"' "$USER_YAML")
fi
echo -e "${GREEN}>> User configuration complete.${NC}"

# ==============================================================================
# 3. SYSTEM TUNING (K8s & GNOME)
# ==============================================================================
echo -e "${YELLOW}>> Applying Kernel and GNOME settings...${NC}"

# K8s Tuning & IPv6 Disable
cat <<EOF > /etc/sysctl.d/90-k8s-tuning.conf
fs.inotify.max_user_instances = 1024
fs.inotify.max_user_watches = 524288
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl --system

# GNOME Desktop Power Settings (system-wide dconf policy — works without a display)
mkdir -p /etc/dconf/db/local.d
cat <<EOF > /etc/dconf/db/local.d/01-power-settings
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'
idle-dim=false
power-button-action='interactive'

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/Brand-Awareness-Geeko-Background-17.png'
picture-uri-dark='file:///usr/share/backgrounds/Brand-Awareness-Geeko-Background-17.png'
picture-options='zoom'

[org/gnome/desktop/screensaver]
picture-uri='file:///usr/share/backgrounds/Brand-Awareness-Geeko-Background-17.png'
EOF
dconf update

# Create the dconf profile to ensure system settings are applied for all users
cat <<EOF > /etc/dconf/profile/user
user-db:user
system-db:local
EOF

# Copy background asset to system directory
mkdir -p /usr/share/backgrounds
if [ -f "$ASSET_DIR/Brand-Awareness-Geeko-Background-17.png" ]; then
    cp "$ASSET_DIR/Brand-Awareness-Geeko-Background-17.png" /usr/share/backgrounds/
    chmod 644 /usr/share/backgrounds/Brand-Awareness-Geeko-Background-17.png
fi

# ==============================================================================
# 4. GLOBAL BASH CUSTOMIZATION
# ==============================================================================
cat <<EOF > /etc/bash.bashrc.local
alias ll='ls -la'
alias k='kubectl'
if [[ \$- == *i* ]]; then
    command -v fastfetch >/dev/null 2>&1 && fastfetch
fi
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml:/etc/rancher/k3s/k3s.yaml
EOF

# ==============================================================================
# 4a. VS CODE (Microsoft repo)
# ==============================================================================
echo -e "${YELLOW}>> Installing VS Code...${NC}"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
zypper addrepo https://packages.microsoft.com/yumrepos/vscode vscode
zypper --gpg-auto-import-keys ref
zypper --gpg-auto-import-keys in -y code

# ==============================================================================
# 4b. MULTIMEDIA CODECS (Packman)
# ==============================================================================
echo -e "${YELLOW}>> Adding Packman repo and installing media codecs...${NC}"
zypper addrepo -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
zypper --gpg-auto-import-keys ref
# Switch multimedia packages to Packman builds (enables full codec support)
zypper --gpg-auto-import-keys dup --from packman --allow-vendor-change -y
zypper --gpg-auto-import-keys in -y ffmpeg gstreamer-plugins-bad gstreamer-plugins-ugly \
             gstreamer-plugins-libav vlc

# ==============================================================================
# 5. ARCHITECTURE-AWARE BINARIES (Kubectl, Helm, K9s)
# ==============================================================================
ARCH=$(uname -m)
BIN_ARCH="amd64"
[[ "$ARCH" == "aarch64" ]] && BIN_ARCH="arm64"

echo -e "${YELLOW}>> Downloading CLI tools for $ARCH...${NC}"

# Kubectl
K8S_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt || echo "v1.30.0")
curl -fsSL -O "https://dl.k8s.io/release/${K8S_VER}/bin/linux/${BIN_ARCH}/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

# Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# K9s (with fallback for GitHub API limits)
K9S_VER=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$K9S_VER" ] || [[ "$K9S_VER" == *"rate limit"* ]]; then
    K9S_VER="v0.32.4"
    echo -e "${YELLOW}⚠️ GitHub API Throttled. Using fallback version $K9S_VER${NC}"
fi
curl -fsSL -o k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_${BIN_ARCH}.tar.gz"
tar -xzf k9s.tar.gz k9s && install -m 0755 k9s /usr/local/bin/k9s && rm k9s k9s.tar.gz

# ==============================================================================
# 6. FLATPAK & STREAMCONTROLLER RESTORE
# ==============================================================================
echo -e "${YELLOW}>> Configuring Flatpak and StreamController...${NC}"
# TERM=dumb prevents flatpak's progress bar from sending terminal escape sequences
# that get echoed as garbage when the script is piped via curl
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>&1 | cat
flatpak install --system -y flathub com.core447.StreamController 2>&1 | cat

while IFS= read -r USER; do
    USER_HOME="/home/$USER"
    SC_VAR_DIR="$USER_HOME/.var/app/com.core447.StreamController"

    if [ -f "$ASSET_DIR/streamcontroller-config.tar.gz" ]; then
        echo -e "${YELLOW}>> Restoring StreamController config for $USER...${NC}"
        mkdir -p "$SC_VAR_DIR"
        tar -xzf "$ASSET_DIR/streamcontroller-config.tar.gz" -C "$SC_VAR_DIR/"
        chown -R "$USER:$USER" "$USER_HOME/.var"
    fi
done < <(yq e '.users[].name' $USER_YAML)

# ==============================================================================
# 7. FINAL SYSTEM CONFIG
# ==============================================================================
firewall-cmd --permanent --add-port=6443/tcp --quiet
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 --quiet
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 --quiet
firewall-cmd --reload --quiet

hostnamectl hostname p500

echo -e "${YELLOW}✅ Setup Complete! A reboot is recommended.${NC}"
