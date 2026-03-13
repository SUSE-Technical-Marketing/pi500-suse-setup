# Raspberry Pi 500 Demo Station Setup

Automated setup script for configuring a **Raspberry Pi 500** running **openSUSE Tumbleweed** as a SUSE demo station. One curl command gets you from a fresh OS install to a fully configured demo-ready system.

## What It Does

- Creates user accounts (`erin`, `sles`) with passwordless sudo
- Installs and configures SSH key access
- Applies kernel tuning for Kubernetes workloads
- Disables IPv6 and configures GNOME power settings (no sleep/screensaver)
- Installs core packages: `git`, `vim`, `curl`, `fastfetch`, `chromium`, `flatpak`, and more
- Adds the **Packman** repo and installs full multimedia codec support (H.264, MP3, AAC, etc.)
- Downloads `kubectl`, `helm`, and `k9s` (architecture-aware, works on ARM64)
- Installs **StreamController** via Flatpak and restores default config
- Configures firewall rules for Kubernetes (ports 6443, pod/service CIDRs)
- Sets hostname to `p500`
- Clones this repo to `/opt/pi500-suse-setup` for assets (desktop images, StreamController defaults)

## Requirements

- Raspberry Pi 500 (ARM64/aarch64)
- Fresh install of **openSUSE Tumbleweed**
- Internet connection
- Run as root

## Quick Start

```bash
curl -fsSL "https://raw.githubusercontent.com/SUSE-Technical-Marketing/pi500-suse-setup/main/setup.sh" | sudo bash
```

After the script completes, reboot:

```bash
sudo reboot
```

## Updating Passwords

To generate a new password hash for the `USERS` array in `setup-pi-500+.sh`, run:

```bash
openssl passwd -6
```

Enter and confirm your password when prompted. Copy the output hash into the script:

```bash
USERS=(
    "erin:<paste hash here>"
    "sles:<paste hash here>"
)
```

## Repo Structure

```
.
├── setup-pi-500+.sh              # Main setup script
└── assets/
    └── streamcontroller-config.tar.gz  # Default StreamController layout
```
