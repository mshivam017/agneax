#!/usr/bin/env bash
# Agneax OS ISO Builder Script
# Designed to be run on Ubuntu/Debian or inside GitHub Actions

set -e
set -o pipefail

WORKDIR="$(pwd)/build"
ROOTFS="$WORKDIR/rootfs"
IMAGE="$WORKDIR/image"
ISO_OUT="$WORKDIR"

echo "=== Agneax OS ISO Builder ==="
echo "Working directory: $WORKDIR"

# Ensure we are running as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (sudo)"
  exit 1
fi

# Validate WORKDIR before deletion (Step 9)
if [ -z "$WORKDIR" ] || [ "$WORKDIR" = "/" ] || [ "$WORKDIR" = "." ]; then
  echo "Error: Invalid WORKDIR value: '$WORKDIR'"
  exit 1
fi

# Clean previous build directories
echo "Cleaning old build files..."
umount -lf "$ROOTFS/proc" || true
umount -lf "$ROOTFS/sys" || true
umount -lf "$ROOTFS/dev/pts" || true
umount -lf "$ROOTFS/dev" || true
rm -rf "$WORKDIR"

# Create directories
mkdir -p "$WORKDIR"
mkdir -p "$ROOTFS"
mkdir -p "$IMAGE/live"
mkdir -p "$IMAGE/boot/grub"

# Setup cleanup trap handler for failed chroot mounts (Step 9)
cleanup() {
  echo "=== Cleaning up mounts ==="
  umount -lf "$ROOTFS/proc" || true
  umount -lf "$ROOTFS/sys" || true
  umount -lf "$ROOTFS/dev/pts" || true
  umount -lf "$ROOTFS/dev" || true
}
trap cleanup EXIT INT TERM

# Install base system using debootstrap
echo "Debootstrapping minimal Debian system..."
debootstrap --arch=amd64 bookworm "$ROOTFS" http://deb.debian.org/debian/

# Mount virtual filesystems for chroot
echo "Mounting virtual filesystems..."
mount -t proc none "$ROOTFS/proc"
mount -t sysfs none "$ROOTFS/sys"
mount -o bind /dev "$ROOTFS/dev"
mount -o bind /dev/pts "$ROOTFS/dev/pts"

# Generate locale configuration inside chroot
echo "Configuring locales..."
cat <<'EOF' > "$ROOTFS/tmp/configure_chroot.sh"
#!/usr/bin/env bash
set -e

# Update apt repositories
echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list
echo "deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list

apt-get update

# Prevent interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Install essential kernel and live boot utilities
apt-get install -y --no-install-recommends \
  linux-image-amd64 \
  live-boot \
  systemd-sysv \
  dbus

# Install network tools
apt-get install -y --no-install-recommends \
  network-manager \
  wireless-tools \
  ufw \
  iptables

# Install custom desktop stack and PySide6 dependencies
apt-get install -y --no-install-recommends \
  weston \
  xwayland \
  lightdm \
  python3 \
  python3-pip \
  libgl1-mesa-dri \
  libxkbcommon-x11-0 \
  libxcb-cursor0 \
  pipewire \
  pipewire-audio-client-libraries \
  sudo \
  git \
  curl

# Install PySide6 via pip inside the chroot
pip3 install --break-system-packages PySide6

# Configure user
echo "agneax-os" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "127.0.1.1 agneax-os" >> /etc/hosts

# Create live user
useradd -m -s /bin/bash agneax
echo "agneax:agneax" | chpasswd
usermod -aG sudo,video,audio,cdrom agneax
echo "agneax ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Enable system services
systemctl enable lightdm
systemctl enable NetworkManager
systemctl enable ufw

# Add agneax-core systemd service (Step 3)
cat <<'LEOF' > /etc/systemd/system/agneax-core.service
[Unit]
Description=Agneax OS System Telemetry & Privilege Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/agneax-core
Restart=always
RestartSec=3
NoNewPrivileges=true
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=true

[Install]
WantedBy=multi-user.target
LEOF

systemctl enable agneax-core

# Set up autostart for weston and custom Agneax shell
mkdir -p /etc/lightdm/lightdm.conf.d
cat <<'LEOF' > /etc/lightdm/lightdm.conf.d/agneax.conf
[Seat:*]
autologin-user=agneax
autologin-user-timeout=0
user-session=agneax-wayland
LEOF

mkdir -p /usr/share/wayland-sessions
cat <<'LEOF' > /usr/share/wayland-sessions/agneax-wayland.desktop
[Desktop Entry]
Name=Agneax Desktop
Comment=Fast, beautiful and secure QML desktop shell
Exec=/usr/bin/agneax-session-start
Type=Application
DesktopNames=Agneax
LEOF

cat <<'LEOF' > /usr/bin/agneax-session-start
#!/usr/bin/env bash
# Start Weston compositor in fullscreen mode and autostart Agneax Shell
weston --backend=drm --shell=kiosk-shell.so --continue-without-input --startup-cmd="/opt/agneax/desktop/run.sh"
LEOF
chmod +x /usr/bin/agneax-session-start

clean_up() {
  apt-get clean
  rm -rf /var/lib/apt/lists/*
  rm -f /tmp/configure_chroot.sh
}

clean_up
EOF

# Execute script inside chroot
chmod +x "$ROOTFS/tmp/configure_chroot.sh"
chroot "$ROOTFS" /tmp/configure_chroot.sh

echo "Copying custom applications and configurations into rootfs..."

# Copy built Rust application
mkdir -p "$ROOTFS/usr/bin"
if [ -f "packages/agneax-core/target/release/agneax-core" ]; then
  cp "packages/agneax-core/target/release/agneax-core" "$ROOTFS/usr/bin/agneax-core"
  chmod +x "$ROOTFS/usr/bin/agneax-core"
  echo "Rust Daemon installed successfully."
else
  echo "Warning: packages/agneax-core/target/release/agneax-core not found. Skipping."
fi

# Copy built C++ helpers
mkdir -p "$ROOTFS/usr/lib"
if [ -f "desktop/cpp_src/build/libcompositor_helper.so" ]; then
  cp "desktop/cpp_src/build/libcompositor_helper.so" "$ROOTFS/usr/lib/libcompositor_helper.so"
  echo "C++ Layout Helper installed successfully."
fi

# Copy desktop and applications code
mkdir -p "$ROOTFS/opt/agneax/desktop"
mkdir -p "$ROOTFS/opt/agneax/control-center"
mkdir -p "$ROOTFS/opt/agneax/installer"
mkdir -p "$ROOTFS/opt/agneax/branding"

cp -R desktop/* "$ROOTFS/opt/agneax/desktop/" || true
cp -R control-center/* "$ROOTFS/opt/agneax/control-center/" || true
cp -R installer/* "$ROOTFS/opt/agneax/installer/" || true
cp -R branding/* "$ROOTFS/opt/agneax/branding/" || true

# Install Agneax Store Debian Package (Step 7)
cp "packages/agneax-store_1.0.0_amd64.deb" "$ROOTFS/tmp/"
chroot "$ROOTFS" dpkg -i /tmp/agneax-store_1.0.0_amd64.deb || true
rm -f "$ROOTFS/tmp/agneax-store_1.0.0_amd64.deb"

# Copy configs (lightdm, network, rules)
cp -R configs/* "$ROOTFS/" || true

# Configure startup run script inside rootfs
cat <<'EOF' > "$ROOTFS/opt/agneax/desktop/run.sh"
#!/usr/bin/env bash
# Startup script for Agneax Desktop environment inside Weston
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_SHELL_INTEGRATION=kiosk-shell
cd /opt/agneax/desktop
python3 main.py
EOF
chmod +x "$ROOTFS/opt/agneax/desktop/run.sh"

# Extract Kernel and Initrd from chroot before packaging
echo "Extracting kernel and initrd..."
KERNEL=$(ls "$ROOTFS/boot/vmlinuz-"* | head -n 1)
INITRD=$(ls "$ROOTFS/boot/initrd.img-"* | head -n 1)

cp "$KERNEL" "$IMAGE/live/vmlinuz"
cp "$INITRD" "$IMAGE/live/initrd"

# Unmount filesystems before packaging squashfs
echo "Unmounting chroot filesystems..."
umount -lf "$ROOTFS/proc"
umount -lf "$ROOTFS/sys"
umount -lf "$ROOTFS/dev/pts"
umount -lf "$ROOTFS/dev"

# Build SquashFS image
echo "Creating filesystem.squashfs (this may take a few minutes)..."
mksquashfs "$ROOTFS" "$IMAGE/live/filesystem.squashfs" -comp xz -e boot

# Create GRUB boot configuration
echo "Configuring bootloader (GRUB)..."
cat <<'EOF' > "$IMAGE/boot/grub/grub.cfg"
set default=0
set timeout=5

insmod ext2
insmod fat
insmod iso9660

menuentry "Agneax OS Live (Standard Mode)" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live quiet splash ---
    initrd /live/initrd
}

menuentry "Agneax OS (Safe Graphics Mode)" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live nomodeset quiet splash ---
    initrd /live/initrd
}
EOF

# Create BIOS and EFI bootable hybrid ISO
echo "Generating bootable hybrid ISO with grub-mkrescue..."
grub-mkrescue -o "$ISO_OUT/agneax-os-amd64.iso" "$IMAGE"

echo "=== Agneax OS ISO Build Complete! ==="
echo "Output path: $ISO_OUT/agneax-os-amd64.iso"
