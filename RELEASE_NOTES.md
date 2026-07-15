# Agneax OS Release Notes

---

## 🚀 Agneax OS v1.1.0-alpha (Current Prototype)
This release introduces advanced graphics hardening, premium boot optimizations, and complete hardware integration for settings, network, and diagnostics.

### 🌟 Key Enhancements in v1.1.0-alpha
- **Ubuntu-style "Try or Install" Greeting**: Automatically detects live environments on boot via kernel command lines and guides users through disk installations or live desktop previews.
- **Widgets Dashboard & Sticky Notes**: A slide-out panel (`Super + W`) displaying calendar widgets, live CPU/RAM metrics, and disk-persisted sticky note areas.
- **Dynamic Taskbar Layout Toggling**: Fast layout switcher allowing seamless toggling between a standard bottom Panel and a floating centered Dock launcher with zoom effects.
- **Night Light warming filter**: Settings control for an overlay screen warmth tint.
- **Hardware Settings Integration**:
  - **Wi-Fi Scanner**: Active network list polling and connection hooks powered by `nmcli` inside Settings.
  - **Audio Engine**: Direct WirePlumber (`wpctl`) volume sink slider integration.
  - **Battery Diagnostics**: Real diagnostics data fed directly from `sysfs` capacity and charging metrics inside the Rust daemon.
  - **Dev Stack Installer**: One-click developer module setup launcher (Git, Node, Rust, Docker).
- **Boot Hardening & Fail-safe Graphics**:
  - **Triple-Fallback graphics compositor**: Automatic failover sequence (OpenGL Weston -> Pixman Weston -> X11 + Openbox) to guarantee display output on any graphics card or VM driver.
  - **Elite Boot Speeds**: Optimized initrd packaging (`update-initramfs` after assets), multithreaded SquashFS decompression (`squashfs.threads=0`), GRUB countdown reduction (`timeout=1`), and masked blocking startup services.
  - **Flicker-free Plymouth splash screen**: High-definition (`1024x256`) anti-aliased logo, dynamic alignment centering (`WatermarkVerticalAlignment=0.42`), and custom colorized loaders.

---

## 🚀 Agneax OS v1.0.0-alpha (Initial Release)
This release provides a preview of our custom Wayland desktop environment, system daemon, package store integration, and installation wizard.

### 🌟 Key Features in v1.0.0-alpha
- **Agneax Desktop Shell**: Modular QML-based workspace featuring a clean taskbar panel, applications start menu, sound/settings dock, and automatic tiling/snap layouts.
- **System Service Daemon (`agneax-core`)**: Performance-optimized telemetry and privileged operations manager written in Rust, communicating via local Unix sockets (`/run/agneax-core.sock`).
- **Compositor Helper**: C++ math engine bound via `ctypes` that calculates window sizes on grid setups.
- **Agneax Store**: Integrated software manager prototype supporting local package installations and APT/dpkg hooks.
- **Control Center**: Dynamic settings app managing themes, accents, and firewall configurations.
- **System Installer**: Modern onboarding wizard highlighting target drive detection and partition steps.
