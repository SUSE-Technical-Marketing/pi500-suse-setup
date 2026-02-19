# Pi 500+ openSUSE-Style GNOME Setup

This repository contains an automation script designed to transform a fresh installation of **Raspberry Pi OS "Trixie" (Debian 13)** on a **Raspberry Pi 500+** into a full GNOME workstation with an openSUSE (Gecko/Green) aesthetic.

## 🎯 Goal
To provide a repeatable, one-command setup for deploying a polished, green-themed GNOME desktop environment across multiple Pi 500+ units, replacing the default PIXEL/LXDE interface.

## 📋 Prerequisites

* **Hardware:** Raspberry Pi 500+ (or Raspberry Pi 5).
* **OS:** Raspberry Pi OS 64-bit (Trixie/Debian 13 branch).
    * *Note: Start with "Raspberry Pi OS Lite" for the cleanest result, but the script supports the Desktop version as well.*
* **Internet Connection:** Required for downloading packages and assets.

## 🚀 Quick Start

1.  **Open a terminal** on your fresh Pi installation.
2.  **Clone this repository** and enter the directory:
    ```bash
    git clone [https://github.com/YourUsername/pi500-suse-setup.git](https://github.com/YourUsername/pi500-suse-setup.git)
    cd pi500-suse-setup
    ```
3.  **Make the script executable**:
    ```bash
    chmod +x setup.sh
    ```
4.  **Run the installer**:
    ```bash
    ./setup.sh
    ```
5.  **Reboot** when prompted:
    ```bash
    sudo reboot
    ```

## 🛠 What This Script Does

1.  **System Update:** Runs `apt update` and `apt full-upgrade` to ensure the Trixie base is current.
2.  **GNOME Installation:** Installs the full `task-gnome-desktop` environment, ensuring a modern, touch-friendly, and smooth Wayland experience on the Pi 500+ hardware.
3.  **Theming (The "SUSE" Look):**
    * **Icons:** Installs and applies `papirus-icon-theme` (Green variant) to mimic the polished look of openSUSE.
    * **Fonts:**