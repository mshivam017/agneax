# Agneax OS v1.0.0-alpha Release Notes

We are excited to announce the first alpha prototype release of **Agneax OS**!

This release provides a preview of our custom Wayland desktop environment, system daemon, package store integration, and installation wizard.

## 🚀 Key Features in this Release
- **Agneax Desktop Shell**: Modular QML-based workspace featuring a clean taskbar panel, applications start menu, sound/settings dock, and automatic tiling/snap layouts.
- **System Service Daemon (`agneax-core`)**: Performance-optimized telemetry and privileged operations manager written in Rust, communicating via local Unix sockets (`/run/agneax-core.sock`).
- **Compositor Helper**: C++ math engine bound via `ctypes` that calculates window sizes on grid setups.
- **Agneax Store**: Integrated software manager prototype supporting local package installations and APT/dpkg hooks.
- **Control Center**: Dynamic settings app managing themes, accents, and firewall configurations.
- **System Installer**: Modern onboarding wizard highlighting target drive detection and partition steps.

## 🛠️ Known Issues / Limitations (Alpha Stage)
- The Installer is currently operating in **Simulation Mode** (disclaimer overlays are shown on welcome slides).
- High-performance GPU acceleration fallback is optimized for VirtualBox **VMSVGA** graphics controllers. Refer to the [Build Guide](docs/build.md) for VM VM settings.
