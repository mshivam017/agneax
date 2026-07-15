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

# Install hardware drivers and firmware for GPU, WiFi, and Bluetooth (Intel, AMD, NVIDIA, VMs)
apt-get install -y --no-install-recommends \
  firmware-linux \
  firmware-linux-free \
  firmware-linux-nonfree \
  firmware-iwlwifi \
  firmware-realtek \
  firmware-atheros \
  xserver-xorg-video-all \
  xserver-xorg-input-all \
  va-driver-all \
  vdpau-driver-all

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
  lightdm-gtk-greeter \
  dbus-user-session \
  policykit-1 \
  plymouth \
  plymouth-themes \
  alsa-utils \
  python3 \
  python3-pip \
  qt6-wayland \
  libegl1 \
  libgl1 \
  libgles2 \
  mesa-utils \
  dbus-x11 \
  xdg-utils \
  libgl1-mesa-dri \
  libxkbcommon-x11-0 \
  libxcb-cursor0 \
  libxcb-keysyms1 \
  libxcb-randr0 \
  libxcb-xinerama0 \
  libxcb-icccm4 \
  libxcb-image0 \
  libxcb-render-util0 \
  libxkbcommon0 \
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
groupadd -r autologin || true
useradd -m -s /bin/bash agneax
echo "agneax:agneax" | chpasswd
usermod -aG sudo,video,audio,cdrom,autologin agneax
echo "agneax ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Enable system services
systemctl enable lightdm
systemctl enable NetworkManager
systemctl enable ufw
systemctl set-default graphical.target

# Configure initramfs tools to use zstd compression for faster boot (Step 1)
if [ -f /etc/initramfs-tools/initramfs.conf ]; then
  sed -i 's/COMPRESS=gzip/COMPRESS=zstd/g' /etc/initramfs-tools/initramfs.conf
fi

# Configure Plymouth default bootloader splash theme (Step 1)
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme -R spinner || true
fi

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
autologin-session=agneax-wayland
greeter-session=lightdm-gtk-greeter
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
set -u

export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_SHELL_INTEGRATION=kiosk-shell

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# 1. Try launching Weston with default OpenGL renderer
echo "Attempting to launch Weston with OpenGL renderer..." > /tmp/weston-start.log
dbus-run-session -- weston \
  --backend=drm-backend.so \
  --shell=kiosk-shell.so \
  --continue-without-input \
  --log=/tmp/weston.log \
  -- /opt/agneax/desktop/run.sh

exit_code=$?
echo "Weston exited with code $exit_code" >> /tmp/weston-start.log

# 2. If it crashed (exit_code != 0), fall back to Pixman software renderer!
if [ $exit_code -ne 0 ]; then
  echo "OpenGL failed. Falling back to Pixman software renderer..." >> /tmp/weston-start.log
  exec dbus-run-session -- weston \
    --backend=drm-backend.so \
    --use-pixman \
    --shell=kiosk-shell.so \
    --continue-without-input \
    --log=/tmp/weston.log \
    -- /opt/agneax/desktop/run.sh
fi
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

# Package the Agneax Store from local source dynamically (Step 5 of analysis)
echo "Packaging Agneax Store dynamically from current workspace sources..."
chmod +x ./scripts/package_store.sh
./scripts/package_store.sh

# Generate PNG wallpaper from SVG vector for GRUB background (Step 2)
echo "Generating PNG wallpaper and text-based boot logo..."
python3 -c '
try:
    from PySide6.QtGui import QPixmap, QPainter, QFont, QColor
    from PySide6.QtSvg import QSvgRenderer
    from PySide6.QtCore import QSize, Qt, QPoint
    
    # Render Wallpaper
    renderer_wp = QSvgRenderer("branding/wallpaper.svg")
    pixmap_wp = QPixmap(QSize(1920, 1080))
    pixmap_wp.fill()
    painter_wp = QPainter(pixmap_wp)
    renderer_wp.render(painter_wp)
    painter_wp.end()
    pixmap_wp.save("build/wallpaper.png")
    print("PNG wallpaper generated successfully.")
    
    # Render Text-based Boot Logo ("Agnea" in white, "X" in orange)
    pixmap_logo = QPixmap(QSize(512, 128))
    pixmap_logo.fill(Qt.transparent)
    painter_logo = QPainter(pixmap_logo)
    painter_logo.setRenderHint(QPainter.Antialiasing)
    painter_logo.setRenderHint(QPainter.TextAntialiasing)
    
    font = QFont("Sans-Serif", 48, QFont.Bold)
    painter_logo.setFont(font)
    
    fm = painter_logo.fontMetrics()
    w_agnea = fm.horizontalAdvance("Agnea")
    w_x = fm.horizontalAdvance("X")
    total_w = w_agnea + w_x
    start_x = (512 - total_w) // 2
    baseline_y = 64 + (fm.ascent() - fm.descent()) // 2
    
    # Draw "Agnea" in White
    painter_logo.setPen(QColor("#FFFFFF"))
    painter_logo.drawText(QPoint(start_x, baseline_y), "Agnea")
    
    # Draw "X" in Premium Bright Orange
    painter_logo.setPen(QColor("#FF6600"))
    painter_logo.drawText(QPoint(start_x + w_agnea, baseline_y), "X")
    
    painter_logo.end()
    pixmap_logo.save("build/logo.png")
    print("Text-based boot logo generated successfully.")
except Exception as e:
    print(f"Warning: Failed to generate PNG assets using PySide6: {e}")
' || true

# Copy generated PNG wallpaper and logos
if [ -f "build/wallpaper.png" ]; then
  mkdir -p "$IMAGE/boot/grub"
  cp "build/wallpaper.png" "$IMAGE/boot/grub/wallpaper.png"
  mkdir -p "$ROOTFS/opt/agneax/branding"
  cp "build/wallpaper.png" "$ROOTFS/opt/agneax/branding/wallpaper.png"
fi

if [ -f "build/logo.png" ]; then
  mkdir -p "$ROOTFS/usr/share/plymouth/themes/spinner"
  cp "build/logo.png" "$ROOTFS/usr/share/plymouth/themes/spinner/watermark.png"
  mkdir -p "$ROOTFS/usr/share/plymouth"
  cp "build/logo.png" "$ROOTFS/usr/share/plymouth/debian-logo.png"
fi

# Install Agneax Store Debian Package (Step 7)
cp "build/agneax-store_1.0.0_amd64.deb" "$ROOTFS/tmp/"
chroot "$ROOTFS" dpkg -i /tmp/agneax-store_1.0.0_amd64.deb || true
rm -f "$ROOTFS/tmp/agneax-store_1.0.0_amd64.deb"

# Copy configs (lightdm, network, rules)
cp -R configs/* "$ROOTFS/" || true

# Configure startup run script inside rootfs (Step 4 of analysis)
cat <<'EOF' > "$ROOTFS/opt/agneax/desktop/run.sh"
#!/usr/bin/env bash
# Startup script for Agneax Desktop environment inside Weston
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_SHELL_INTEGRATION=kiosk-shell
export QSG_RENDER_LOOP=threaded
cd /opt/agneax/desktop
python3 main.py >> /tmp/agneax-desktop.log 2>&1
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
mksquashfs "$ROOTFS" "$IMAGE/live/filesystem.squashfs" -comp zstd -b 1M -e boot

# Create GRUB boot configuration
echo "Configuring bootloader (GRUB)..."
cat <<'EOF' > "$IMAGE/boot/grub/grub.cfg"
set default=0
set timeout=5

insmod ext2
insmod fat
insmod iso9660
insmod all_video
insmod png

background_image /boot/grub/wallpaper.png
set menu_color_normal=cyan/black
set menu_color_highlight=black/cyan

menuentry "Agneax OS Live (Standard Mode)" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live quiet splash ---
    initrd /live/initrd
}

menuentry "Agneax OS (Safe Graphics Mode)" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live nomodeset loglevel=7 ---
    initrd /live/initrd
}

menuentry "Agneax OS Debug Console" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live systemd.unit=multi-user.target loglevel=7 ---
    initrd /live/initrd
}
EOF

# Create BIOS and EFI bootable hybrid ISO
echo "Generating bootable hybrid ISO with grub-mkrescue..."
grub-mkrescue -o "$ISO_OUT/agneax-os-amd64.iso" "$IMAGE"

echo "=== Agneax OS ISO Build Complete! ==="
echo "Output path: $ISO_OUT/agneax-os-amd64.iso"
