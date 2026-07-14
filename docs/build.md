# Agneax OS Build Guide

This document describes how to build a bootable hybrid ISO of **Agneax OS** from scratch on a Linux system (or inside WSL2/Docker).

## Prerequisites

You need an Ubuntu 24.04 / Debian 12 environment with `sudo` permissions. Run the following command to install host build dependencies:

```bash
sudo chmod +x scripts/install_deps.sh
sudo ./scripts/install_deps.sh
```

This will install the following packages:
- `debootstrap`: To build the minimal base system rootfs.
- `xorriso`, `mtools`: To generate the bootable ISO file.
- `squashfs-tools`: To package the rootfs.
- `grub-pc-bin`, `grub-efi-amd64-bin`: For bootloader files.
- `cmake`, `build-essential`: To compile C++ helpers.
- `rustup` & `cargo`: To compile the Rust system daemon.

---

## Build Steps

### Step 1: Compile the Rust System Daemon
Navigate to the Rust package and build the production binary:
```bash
cd packages/agneax-core
cargo build --release
```
The output binary will be located at `packages/agneax-core/target/release/agneax-core`.

### Step 2: Compile the C++ Compositor Layout Helper
Configure CMake and make the shared library:
```bash
mkdir -p desktop/cpp_src/build
cd desktop/cpp_src/build
cmake ..
make
```
The output shared library will be located at `desktop/cpp_src/build/libcompositor_helper.so`.

### Step 3: Run the ISO Builder Script
Run the automated script as root from the root directory of the repository:
```bash
sudo ./scripts/build_iso.sh
```
This script will:
1. Fetch a clean Debian 12 minimal base distribution.
2. Bind mount `/proc`, `/sys`, `/dev` and chroot in.
3. Install display server Wayland, Weston kiosk shell, LightDM, PySide6, and audio components.
4. Copy our built Rust daemon, C++ layout library, desktop python files, settings configs, and themes.
5. Setup automated Live user log-in triggers.
6. Package the files into `filesystem.squashfs`.
7. Generate BIOS/EFI hybrid boot files and run `xorriso` to create the final ISO.

### Step 4: Verify Output
The built ISO will be saved at:
`build/agneax-os-amd64.iso`

---

## 🛠️ VirtualBox Running & Troubleshooting Guide

If the ISO fails to boot cleanly or displays a blank/black screen with only a mouse cursor, please check the settings and run the following diagnostic procedures.

### A. Recommended VirtualBox VM Parameters
- **Graphics Controller**: Ensure it is set to **VMSVGA** (standard graphics card simulation for Linux/Wayland guests).
- **Video Memory**: Allocate at least **128 MB** of video memory.
- **3D Acceleration**: Toggle **Enable 3D Acceleration** on. If the desktop environment fails to render, toggle it **off** to force CPU software rendering paths.
- **System Memory**: Allocate at least **4 GB** (minimum requirement for the live squashfs image runtime).

### B. Accessing TTY Debug Console
If the graphical environment is blank:
1. Press the VirtualBox **Host Key + F2** (or **Ctrl + Alt + F2**) to switch away from the display server to a virtual TTY terminal.
2. Login with credentials:
   - **Username**: `agneax`
   - **Password**: `agneax`

### C. Live Diagnostics Commands
Once logged into the terminal, run the following queries to determine the error location:

1. **Check Display Server Status**:
   ```bash
   systemctl status lightdm --no-pager
   ```
2. **Review LightDM logs**:
   ```bash
   journalctl -b -u lightdm --no-pager
   ```
3. **Inspect Weston logs**:
   ```bash
   cat /tmp/weston.log
   ```
4. **Inspect Python Desktop app launch logs**:
   ```bash
   cat /tmp/agneax-desktop.log
   ```
5. **Verify PySide6 / Qt6 imports**:
   ```bash
   python3 -c "import PySide6; print(PySide6.__version__)"
   python3 -c "from PySide6.QtWidgets import QApplication; print('Qt widgets OK')"
   ```
6. **Attempt Manual Launch of Desktop Shell**:
   ```bash
   export QT_QPA_PLATFORM=wayland
   export QT_WAYLAND_SHELL_INTEGRATION=kiosk-shell
   cd /opt/agneax/desktop && python3 main.py
   ```


You can test it using QEMU:
```bash
qemu-system-x86_64 -enable-kvm -m 2G -cdrom build/agneax-os-amd64.iso
```
Or flash it to a USB drive using `dd`:
```bash
sudo dd if=build/agneax-os-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```
