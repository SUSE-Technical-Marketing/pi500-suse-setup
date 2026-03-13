#!/bin/bash

# --- openSUSE Raspberry Pi / Rancher Desktop / StreamController Setup ---
# Designed for openSUSE Tumbleweed/Leap on a Raspberry Pi (ARM64)

if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (sudo)"
  exit 1
fi

# Set directory and colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YELLOW='\033[1;33m'
NC='\033[0m'

# ==============================================================================
# 1. USER CONFIGURATION & SUDOERS
# ==============================================================================
# Format: "username:password_hash"
USERS=(
    "erin:\$2y\$10\$M8ZamcBlJG4xMooQSI7M2eAy2vrDrFx4WOG79SrPKjZUU/kDpsRE6"
    "sles:\$6\$rounds=4096\$examplehash\$..." 
)

SSH_KEY_ERIN="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDrkMfTTDxPafXv+E1olBKCqu3ggaRGeitMaJ5iJHr588Bo2PcPY+xlM5iM1WITNBwUtdotxtIPVv25sijeEB4eCn4Sx/460FB9cbucGMUqZeeMZe++ibziT/5vyDQhIBwEpw3tm5qtd1rLJkdIbq6hyxbkH2lr8RKfEGA9CCCTFeX7CPHHsVx3KXoS2TDceVHEaMaNBSpT1wkUJ26WLnbjYIkeTI2tqWmS/zV2u8wE9hyWsKheXRL3P9Ams+n2t4UmjNb0Xs96hkjNb0Xs96hkjHbcl8Pa8dlrOOER9oINWblfbuJR28Q3vlPR/3yLC1JI9o/+Vq92aMRZiA2BMg+uC/vj18GnKwrSJQ1tEt4hnHxwTaMBjBhXuH6AJDL1LxwKMhP8iNHmke/VuIUcjtusRmpDGtVy/Jov506FAN9coWqg0DC7RojwvGaK8SSCHDV6XLZGXg5PuoyiagCRqGsp6Y5FUMtodNLEzvWe3yLS7gOLTEfoddZM9cn+u9jzQVgyqfjT9xUtc= erquill@Erins-MacBook-Pro-2.local"

echo -e "${YELLOW}>> Configuring Users and Sudo access...${NC}"
for entry in "${USERS[@]}"; do
    USERNAME="${entry%%:*}"
    HASH="${entry#*:}"

    if ! id "$USERNAME" &>/dev/null; then
        useradd -m -G wheel -s /bin/bash "$USERNAME"
        echo "$USERNAME:$HASH" | chpasswd -e
        # Set Passwordless Sudo
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME"
        chmod 440 "/etc/sudoers.d/$USERNAME"
    fi
done

# Restore SSH Key for erin
if [ -d "/home/erin" ]; then
    mkdir -p /home/erin/.ssh
    echo "$SSH_KEY_ERIN" > /home/erin/.ssh/authorized_keys
    chown -R erin:erin /home/erin/.ssh
    chmod 700 /home/erin/.ssh
fi

# ==============================================================================
# 2. SYSTEM TUNING (K8s & GNOME)
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

# GNOME Desktop Power Settings for all users
for USERNAME in "${USERS[@]}"; do
    sudo -u "$USERNAME" gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    sudo -u "$USERNAME" gsettings set org.gnome.desktop.session idle-delay 0
    sudo -u "$USERNAME" gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
done

# ==============================================================================
# 3. GLOBAL BASH CUSTOMIZATION
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
# 4. PACKAGE INSTALLATION (Zypper)
# ==============================================================================
echo -e "${YELLOW}>> Installing repositories and packages...${NC}"
zypper ref
zypper addrepo -f https://download.opensuse.org/repositories/isv:/Rancher:/stable/rpm/isv:Rancher:stable.repo
zypper ref
zypper in -y fastfetch curl git bash-completion vim nano iputils wget \
             mc tree bat btop open-iscsi cryptsetup qemu-guest-agent flatpak \
             rancher-desktop

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
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub com.core447.StreamController

for USERNAME in "${USERS[@]}"; do
    USER_HOME="/home/$USERNAME"
    SC_VAR_DIR="$USER_HOME/.var/app/com.core447.StreamController"
    
    if [ -f "$SCRIPT_DIR/assets/streamcontroller-config.tar.gz" ]; then
        echo -e "${YELLOW}>> Restoring StreamController config for $USERNAME...${NC}"
        mkdir -p "$SC_VAR_DIR"
        tar -xzf "$SCRIPT_DIR/assets/streamcontroller-config.tar.gz" -C "$SC_VAR_DIR/"
        chown -R "$USERNAME:$USERNAME" "$USER_HOME/.var"
    fi
done

# ==============================================================================
# 7. FINAL SYSTEM CONFIG
# ==============================================================================
firewall-cmd --permanent --add-port=6443/tcp --quiet
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16 --quiet
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16 --quiet
firewall-cmd --reload --quiet

hostnamectl hostname p500

echo -e "${YELLOW}✅ Setup Complete! A reboot is recommended.${NC}"