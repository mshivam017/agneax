# Agneax OS

[![Build Agneax OS ISO](https://github.com/mshivam017/agneax/actions/workflows/build-iso.yml/badge.svg)](https://github.com/mshivam017/agneax/actions/workflows/build-iso.yml)

**Fast. Beautiful. Secure. Simple. Powerful.**

**Agneax OS** is an open-source Linux operating system (currently in Alpha / Active Prototype stage) based on Debian Stable / Ubuntu LTS. It is designed to combine the simplicity of Windows, the elegance of macOS, and the developer-focused flexibility of Linux.

---

## 🌟 Key Features

- **Agneax Desktop**: A custom Wayland desktop shell written in PySide6 and QML, optimized to run with minimal overhead (idle RAM under 700MB). Features a Windows-style Panel and macOS-style zoom Dock layouts.
- **Widgets Dashboard & Sticky Notes**: Built-in sliding widget tray (`Super + W`) displaying live telemetry graphs, a digital clock/calendar, and persistent sticky notes.
- **Try or Install Boot Wizard**: An Ubuntu-style greeting overlay automatically triggered in live environments, offering non-destructive live trials or direct hard drive installations.
- **Hybrid Compositor Fallback**: A robust display startup engine that automatically cascades from Wayland (OpenGL) to Wayland (Pixman) to native X11 + Openbox to guarantee graphics loading under all hypervisors (VMware, VirtualBox).
- **High-Performance Rust Daemon (`agneax-core`)**: Provides asynchronous system telemetry, package updates, and secure administrative command execution. Handles real sysfs battery diagnostics.
- **C++ Compositor Helper (`libcompositor_helper.so`)**: Handles mathematical window tiling layouts and grid snaps with zero-overhead.
- **Integrated Apps**: Beautifully-designed custom App Store, Settings Control Center (with PipeWire volume controls, nmcli Wi-Fi list scanning, and Night Light warming filters), System Installer, File Manager, and GPU-Accelerated Terminal Emulator.
- **Secure by Default**: Out-of-the-box UFW firewall configs, Secure Boot compatibility, and automatic security updates.
- **Developer & Gaming Ready**: One-click developer stack installs (Rust, Docker, Node, etc.) and pre-configured Wine/Proton/Steam support.

---

## 📂 Repository Structure

```text
AgneaxOS/
├── .github/workflows/    # CI/CD automated ISO build workflows
├── branding/             # Brand logos and vector desktop wallpapers
├── desktop/              # PySide6 desktop launcher and QML components
│   ├── cpp_src/          # C++ compositor layout code
│   └── qml/              # UI screens (panels, menus, overlays)
├── installer/            # OS Disk partitioner and setup wizard
├── store/                # APT & Flatpak package store
├── control-center/       # System settings control panel
├── packages/
│   └── agneax-core/      # Telemetry daemon (Rust)
├── configs/              # Overlay configurations (LightDM, systemd, GRUB)
├── scripts/              # ISO builder and dependencies installer scripts
├── docs/                 # Detailed guides (build, dev, user guides)
├── tests/                # Unit test suites (Python pytest)
└── build/                # Output binaries and generated ISO files
```

---

## 🚀 Quick Start

### 1. Run Unit Tests
To verify layout calculations, API formats, and daemon bridges:
```bash
python tests/test_agneax.py
```

### 2. Run Applications Locally
You can run the desktop applications directly on your development host:
```bash
# Run the Desktop Environment shell
python desktop/main.py

# Run the settings panel
python control-center/main.py

# Run the app store
python store/main.py

# Run the system installer
python installer/main.py
```
*Note: Applications will automatically fall back to simulated/mock mode if they cannot find the native Linux backend dependencies or the Rust system daemon.*

### 3. Build the ISO Image
Refer to the [Build Guide](docs/build.md) for full compilation steps:
```bash
# 1. Install packages
sudo ./scripts/install_deps.sh

# 2. Build Rust daemon
cd packages/agneax-core && cargo build --release && cd ../..

# 3. Build C++ helper
mkdir -p desktop/cpp_src/build && cd desktop/cpp_src/build && cmake .. && make && cd ../../..

# 4. Generate bootable ISO
sudo ./scripts/build_iso.sh
```

---

## 📖 Documentation

- 🛠️ [Build Manual](docs/build.md) - Learn how to build and test the ISO locally or in CI/CD.
- 💻 [Developer Guide](docs/developer.md) - System architecture details, QML styling guides, and app module extensions.
- 📘 [User Guide](docs/user_guide.md) - Installer screens, desktop layouts, and settings tuning details.
