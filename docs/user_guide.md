# Agneax OS User Manual

Welcome to **Agneax OS** — a fast, beautiful, secure, and modern operating system designed for beginners, developers, and gamers.

This guide provides instructions on installing and navigating the Agneax OS desktop environment.

---

## 1. Booting the Live Media & Onboarding Wizard

When you boot from the Agneax OS live media, the GRUB menu will present options:
1. **Agneax OS Live (Standard Mode)**: Recommended. Uses default hardware graphics acceleration with ultra-fast multithreaded SquashFS decompression and silent boot screen transitions.
2. **Agneax OS (Safe Graphics Mode)**: Troubleshooting mode if your GPU rendering fails. Falls back to software rendering options.

Once loaded, the **Onboarding Wizard** will appear automatically:
- **Try Agneax OS**: Closes the welcome dialog, letting you test the system in live memory without changing your computer.
- **Install Agneax OS**: Launches the disk partitioning wizard to begin permanent installation immediately.

---

## 2. Keyboard Shortcuts (Hotkeys)
Navigate the desktop shell instantly using built-in system hotkeys:
- **`Super` (Windows Key)**: Toggle the Applications Start Menu.
- **`Ctrl + Alt + T`**: Launch the GPU-accelerated Terminal Emulator.
- **`Super + W`**: Slide out the Widgets Dashboard tray.
- **`Super + D`**: Clear the desktop (minimize all windows) or restore them.

---

## 3. Desktop Widgets Dashboard
Press `Super + W` to toggle the sliding **Widgets Dashboard**:
- **Clock & Calendar**: Large, premium digital clock and calendar widget.
- **Telemetry Graph Monitors**: Visual CPU and Memory utilization progress trackers.
- **Sticky Notes**: A persistent, autosaved notepad for writing quick developer notes.

---

## 4. Desktop Environment Navigation

Agneax OS runs a custom shell with dynamic taskbar layout modes:
- **Start Menu**: Click search to filter apps. Press `Enter` to autostart the top application match.
- **Taskbar Layout Switcher**: Open **Control Center** -> **Appearance** to toggle between:
  - **Standard Panel** (Windows style bottom taskbar)
  - **Floating Dock** (macOS style dock launcher with mouse hover zoom effects)

---

## 5. Control Center & Settings tuning
Open the **Control Center** to configure advanced options:
- **Appearance**: Adjust system theme (Light/Dark), wallpapers, accent color, and taskbar layout.
- **Wi-Fi Scanner**: Scan live networks, input passwords securely, and check IP addresses.
- **Display & Audio**:
  - **Master Volume**: Control PipeWire sound output directly.
  - **Night Light**: Adjust screen warmth (blue light filter overlay) from 0% to 100%.
- **Developer Mode**: Install Git, Node.js, Rust (Cargo), and Docker with a single click.
- **Firewall**: Fast UFW state toggle blocks.
