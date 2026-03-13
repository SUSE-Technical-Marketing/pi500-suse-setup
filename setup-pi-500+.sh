ARCH=$(uname -m)
BIN_ARCH="amd64"
[[ "$ARCH" == "aarch64" ]] && BIN_ARCH="arm64"

echo "🛠️  Downloading CLI tools for $ARCH..."

# --- Kubectl ---
echo "📥 Installing Kubectl..."
K8S_VER=$(curl -L -s https://dl.k8s.io/release/stable.txt || echo "v1.30.0")
curl -fsSL -O "https://dl.k8s.io/release/${K8S_VER}/bin/linux/${BIN_ARCH}/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl

# --- Helm ---
echo "📥 Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# --- K9s (With API Failure Fallback) ---
echo "📥 Installing K9s..."
# Attempt to get version, fallback to v0.32.4 if API fails
K9S_VER=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$K9S_VER" ] || [[ "$K9S_VER" == *"rate limit"* ]]; then
    K9S_VER="v0.32.4"
    echo "⚠️  GitHub API throttled. Falling back to version $K9S_VER"
fi

curl -fsSL -o k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_${BIN_ARCH}.tar.gz"
if file k9s.tar.gz | grep -q 'gzip compressed data'; then
    tar -xzf k9s.tar.gz k9s
    install -m 0755 k9s /usr/local/bin/k9s
    rm k9s k9s.tar.gz
    echo "✅ K9s $K9S_VER installed."
else
    echo "❌ K9s download failed (likely still rate limited)."
    rm k9s.tar.gz
fi

# --- 6. Firewall & Identity ---
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16
firewall-cmd --reload
hostnamectl hostname p500

echo "✅ Setup complete!"
"test.sh" 122L, 4783B                                                                           113,2         Bot
ARCH=$(uname -m)
BIN_ARCH="amd64"

# --- K9s (With API Failure Fallback) ---
echo "📥 Installing K9s..."
# Attempt to get version, fallback to v0.32.4 if API fails
K9S_VER=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$K9S_VER" ] || [[ "$K9S_VER" == *"rate limit"* ]]; then
    K9S_VER="v0.32.4"
    echo "⚠️  GitHub API throttled. Falling back to version $K9S_VER"
fi

curl -fsSL -o k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_${BIN_ARCH}.tar.gz"
if file k9s.tar.gz | grep -q 'gzip compressed data'; then
    tar -xzf k9s.tar.gz k9s
    install -m 0755 k9s /usr/local/bin/k9s
    rm k9s k9s.tar.gz
    echo "✅ K9s $K9S_VER installed."
else
    echo "❌ K9s download failed (likely still rate limited)."
    rm k9s.tar.gz
fi

# --- 6. Firewall & Identity ---
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16
firewall-cmd --reload
hostnamectl hostname p500

# --- 7. GNOME & Flatpak Updates ---
echo "🖥️  Finalizing Desktop & Flatpak..."
hostnamectl hostname p500

# Ensure the system-wide flathub remote exists
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo "📥 Installing StreamController (Automated)..."
# Use --system to avoid the user/system prompt and -y to skip confirmation
flatpak install --system -y flathub com.core447.StreamController

# Optional: Add the user-level remote you had before
sudo -u $TARGET_USER flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "✅ Setup complete!"
"test.sh" 136L, 5399B                                                                           134,115       Bot

# --- K9s (With API Failure Fallback) ---
echo "📥 Installing K9s..."
# Attempt to get version, fallback to v0.32.4 if API fails
K9S_VER=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -z "$K9S_VER" ] || [[ "$K9S_VER" == *"rate limit"* ]]; then
    K9S_VER="v0.32.4"
    echo "⚠️  GitHub API throttled. Falling back to version $K9S_VER"
fi

curl -fsSL -o k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_${BIN_ARCH}.tar.gz"
if file k9s.tar.gz | grep -q 'gzip compressed data'; then
    tar -xzf k9s.tar.gz k9s
    install -m 0755 k9s /usr/local/bin/k9s
    rm k9s k9s.tar.gz
    echo "✅ K9s $K9S_VER installed."
else
    echo "❌ K9s download failed (likely still rate limited)."
    rm k9s.tar.gz
fi

# --- 6. Firewall & Identity ---
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --zone=trusted --add-source=10.42.0.0/16
firewall-cmd --permanent --zone=trusted --add-source=10.43.0.0/16
firewall-cmd --reload
hostnamectl hostname p500

# --- 7. GNOME & Flatpak Updates ---
echo "🖥️  Finalizing Desktop & Flatpak..."