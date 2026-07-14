# Agneax OS User Manual

Welcome to **Agneax OS** — a fast, beautiful, secure, and modern operating system designed for beginners, developers, and gamers.

This guide provides instructions on installing and navigating the Agneax OS desktop environment.

---

## 1. Booting the Live Media

When you boot from the Agneax OS USB drive, the GRUB menu will present two choices:
1. **Agneax OS Live (Standard Mode)**: Recommended. Uses default hardware graphics acceleration.
2. **Agneax OS (Safe Graphics Mode)**: Troubleshooting mode if your GPU rendering fails. Falls back to software rendering options.

Once loaded, you will automatically log in to the live desktop environment without requiring a password.

---

## 2. System Installation

To install Agneax OS permanently on your drive:
1. Double-click the **Install Agneax** desktop shortcut icon on the desktop screen.
2. **Language & Keyboard**: Select your locale and language options.
3. **Partitioning**: Choose your target storage drive. The installer will format and prepare automatic EFI partitions (`/dev/sda1` FAT32) and the root partition (`/dev/sda2` ext4).
4. **User Details**: Input your administrator account name and system password.
5. **Install**: Click "Install Now". The squashfs file extraction will begin.
6. **Reboot**: Click "Reboot Now" to reboot into your clean, native Agneax OS system.

---

## 3. Desktop Environment Navigation

Agneax OS runs **Agneax Desktop** built on Wayland protocol.

- **Start Menu (Λ icon)**: Located on the bottom left. Click it to view installed applications, search files, check profiles, lock screens, reboot, or shut down.
- **Quick Settings (⚙️ icon)**: Located on the bottom right. Toggle Wi-Fi, Bluetooth, Dark Mode, and Firewall rule cards. Drag volume and screen brightness sliders. Monitor system metrics (CPU, memory, temperature, uptime).
- **Desktop Shortcuts**: Drag and launch shortcuts on the grid.
- **Window Snapping**: Move windows to screen edges to snap them to halves or quarters.

---

## 4. Agneax App Store
Open the **App Store** to manage software:
- Select categories (Developer, Graphics, Gaming, Internet) to filter software.
- Click **Install** to download and configure applications (VS Code, Steam, Firefox, Discord, GIMP).
- Integrates both standard Debian APT packages and modern sandbox Flatpak packages.

---

## 5. Settings & Control Center
Open the **Control Center** to configure options:
- **System**: View CPU, RAM, kernel version, and hardware components details.
- **Appearance**: Adjust system theme, wallpaper, and accent color.
- **Wi-Fi**: Connect to access points and check IP configurations.
- **Firewall**: Easily enable/disable the built-in UFW firewall.
- **Developer Mode**: Toggle developer switches to download GCC, Clang, Docker, Node.js, and Rust tools with a single click.
