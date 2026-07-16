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
  dbus \
  zstd \
  haveged

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
  sddm \
  qml-module-qtgraphicaleffects \
  qml-module-qtquick-controls2 \
  qml-module-qtquick-layouts \
  qml-module-qtquick-window2 \
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
  curl \
  xinit \
  openbox

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
usermod -aG sudo,video,input,render,autologin agneax || true
echo "agneax ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Enable system services
systemctl enable sddm
systemctl enable NetworkManager
systemctl enable ufw
systemctl set-default graphical.target

# Configure initramfs tools to use zstd compression for faster boot (Step 1)
if [ -f /etc/initramfs-tools/initramfs.conf ]; then
  sed -i 's/^#\?[[:space:]]*COMPRESS=.*/COMPRESS=zstd/g' /etc/initramfs-tools/initramfs.conf || true
fi

# Add lightweight virtual GPU drivers for early VM modesetting
echo -e "virtio_gpu\nvboxvideo\nvmwgfx" >> /etc/initramfs-tools/modules

# Mask blocking early services to speed up boot sequence (Phase 4)
systemctl mask keyboard-setup.service || true
systemctl mask console-setup.service || true
systemctl mask apt-daily.timer apt-daily-upgrade.timer || true
systemctl mask NetworkManager-wait-online.service || true
systemctl mask systemd-networkd-wait-online.service || true


# Configure Plymouth default bootloader splash theme (Step 1)
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  plymouth-set-default-theme -R spinner || true
fi

# Set show delay to 0 to make the boot logo appear instantly (Step 2)
mkdir -p /etc/plymouth
cat <<'LEOF' > /etc/plymouth/plymouthd.conf
[Daemon]
Theme=spinner
ShowDelay=0
DeviceTimeout=5
LEOF

# Overwrite Plymouth spinner theme configurations with explicit Watermark logo mappings
PLYMOUTH_SPINNER_CONF="/usr/share/plymouth/themes/spinner/spinner.plymouth"
if [ -f "$PLYMOUTH_SPINNER_CONF" ]; then
  echo "[Plymouth Theme]" > "$PLYMOUTH_SPINNER_CONF"
  echo "Name=Spinner" >> "$PLYMOUTH_SPINNER_CONF"
  echo "Description=A theme that features a simple spinner on a dark background." >> "$PLYMOUTH_SPINNER_CONF"
  echo "ModuleName=two-step" >> "$PLYMOUTH_SPINNER_CONF"
  echo "" >> "$PLYMOUTH_SPINNER_CONF"
  echo "[two-step]" >> "$PLYMOUTH_SPINNER_CONF"
  echo "ImageDir=/usr/share/plymouth/themes/spinner" >> "$PLYMOUTH_SPINNER_CONF"
  echo "HorizontalAlignment=0.5" >> "$PLYMOUTH_SPINNER_CONF"
  echo "VerticalAlignment=0.5" >> "$PLYMOUTH_SPINNER_CONF"
  echo "Transition=fade" >> "$PLYMOUTH_SPINNER_CONF"
  echo "TransitionDuration=0.5" >> "$PLYMOUTH_SPINNER_CONF"
  echo "Watermark=watermark" >> "$PLYMOUTH_SPINNER_CONF"
  echo "WatermarkHorizontalAlignment=0.5" >> "$PLYMOUTH_SPINNER_CONF"
  echo "WatermarkVerticalAlignment=0.42" >> "$PLYMOUTH_SPINNER_CONF"
fi

# Configure Plymouth status text styling (Phase 4)
PLYMOUTH_SPINNER_SCRIPT="/usr/share/plymouth/themes/spinner/spinner.script"
if [ -f "$PLYMOUTH_SPINNER_SCRIPT" ]; then
  sed -i 's/font[[:space:]]*=[[[:space:]]*"[^"]*"/font = "Sans 9"/g' "$PLYMOUTH_SPINNER_SCRIPT"
  sed -i 's/status_entry.SetColor[[[:space:]]*[^)]*)/status_entry.SetColor(0.62, 0.68, 0.75)/g' "$PLYMOUTH_SPINNER_SCRIPT"
fi

# Add SDDM hardware wait delay override (Phase 4)
mkdir -p /etc/systemd/system/sddm.service.d
cat <<'LEOF' > /etc/systemd/system/sddm.service.d/override.conf
[Service]
ExecStartPre=/bin/sh -c 'for i in $(seq 1 20); do [ -e /dev/dri/card0 ] || [ -e /dev/fb0 ] && exit 0; sleep 0.1; done; exit 0'
Restart=always
RestartSec=2
LEOF

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

# Set up autostart and theme for SDDM
cat <<'LEOF' > /etc/sddm.conf
[Theme]
Current=agneax

[Autologin]
User=agneax
Session=agneax
LEOF

mkdir -p /usr/share/xsessions
cat <<'LEOF' > /usr/share/xsessions/agneax.desktop
[Desktop Entry]
Name=Agneax Desktop
Comment=Fast, beautiful and secure QML desktop shell
Exec=/usr/bin/agneax-session-start
Type=Application
DesktopNames=Agneax
LEOF

cat <<'LEOF' > /usr/bin/agneax-session-start
#!/usr/bin/env bash
# Agneax OS Desktop Session Startup Script (Robust Exception Handled)
set -u

# Setup Safe Log File
LOG_FILE="/tmp/agneax-session.log"
echo "=== Agneax Session Startup: $(date) ===" > "$LOG_FILE"
exec 3>&1 4>&2
exec 1>>"$LOG_FILE" 2>&1

echo "User: $(whoami) (UID: $(id -u))"
echo "Environment DISPLAY: ${DISPLAY:-None}"

# Robust XDG_RUNTIME_DIR Setup (Fallback to /tmp if needed)
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if ! mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || ! chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null; then
  echo "Warning: Failed to create or secure $XDG_RUNTIME_DIR. Using fallback in /tmp."
  export XDG_RUNTIME_DIR="/tmp/xdg-runtime-$(id -u)"
  mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null
  chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null
fi

# Clean up stale Wayland sockets to avoid launch conflicts
rm -f "$XDG_RUNTIME_DIR/wayland-*"

# Ensure DBus Session Bus is active
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  echo "Starting private DBus session bus..."
  if command -v dbus-launch >/dev/null 2>&1; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
  else
    echo "Warning: dbus-launch not found. DBus communication might fail."
  fi
fi

# Verify Target Execution Script
RUN_SCRIPT="/opt/agneax/desktop/run.sh"
if [ ! -x "$RUN_SCRIPT" ]; then
  echo "Error: Run script $RUN_SCRIPT not found or not executable. Trying python main.py fallback."
  if [ -f "/opt/agneax/desktop/main.py" ]; then
    cat <<'EOF' > /tmp/agneax-fallback-run.sh
#!/usr/bin/env bash
cd /opt/agneax/desktop
python3 main.py
EOF
    chmod +x /tmp/agneax-fallback-run.sh
    RUN_SCRIPT="/tmp/agneax-fallback-run.sh"
  else
    echo "Fatal: No desktop shell modules found! Falling back to safe terminal shell."
    if command -v xterm >/dev/null 2>&1; then
      exec xterm -geometry 80x24+100+100 -hold -e "echo 'Agneax desktop shell files are missing! Check /opt/agneax/desktop/'; bash"
    else
      sleep 10
      exit 1
    fi
  fi
fi

# Core Session Launch Logic
exit_code=1

if [ -n "${DISPLAY:-}" ]; then
  echo "X11 DISPLAY detected ($DISPLAY). Running desktop shell natively on X11..."
  if command -v openbox >/dev/null 2>&1; then
    echo "Starting openbox window manager..."
    openbox &
  fi
  "$RUN_SCRIPT"
  exit_code=$?
  echo "Desktop shell exited with code $exit_code"
else
  # Native compositor mode (Wayland DRM)
  echo "No X11 DISPLAY. Attempting to start native DRM Weston compositor..."
  if command -v weston >/dev/null 2>&1; then
    weston \
      --backend=drm-backend.so \
      --shell=kiosk-shell.so \
      --idle-time=0 \
      --continue-without-input \
      --log=/tmp/weston.log \
      -- "$RUN_SCRIPT"
    exit_code=$?
    echo "DRM Weston compositor exited with code $exit_code"

    # Fallback to DRM with Software Rendering (Pixman)
    if [ $exit_code -ne 0 ]; then
      echo "OpenGL failed. Falling back to native DRM Weston with Pixman software renderer..."
      weston \
        --backend=drm-backend.so \
        --use-pixman \
        --shell=kiosk-shell.so \
        --idle-time=0 \
        --continue-without-input \
        --log=/tmp/weston.log \
        -- "$RUN_SCRIPT"
      exit_code=$?
      echo "Pixman DRM Weston compositor exited with code $exit_code"
    fi
  else
    echo "Warning: weston is not installed!"
  fi

  # Fallback to local X server if compositor failed completely
  if [ $exit_code -ne 0 ]; then
    echo "Weston failed completely. Starting fallback local Xorg server..."
    if command -v startx >/dev/null 2>&1; then
      startx "$RUN_SCRIPT" -- :0 vt7
      exit_code=$?
    else
      echo "startx not available. Trying manual Xorg server initialization..."
      export DISPLAY=:0
      if command -v Xorg >/dev/null 2>&1; then
        Xorg :0 vt7 -nofreevt -novtswitch &
        sleep 1
        if command -v openbox >/dev/null 2>&1; then
          openbox &
        fi
        "$RUN_SCRIPT"
        exit_code=$?
      else
        echo "Fatal: No display servers or compositors could be initialized!"
      fi
    fi
  fi
fi

# Anti-Loop Protection (If session exited too fast, sleep to prevent CPU hogging)
if [ $exit_code -ne 0 ]; then
  echo "Session terminated abnormally with code $exit_code. Initiating anti-loop delay."
  sleep 5
fi

exit $exit_code
LEOF
chmod +x /usr/bin/agneax-session-start

# Phase 1: Set Systemd Default Boot Timeout to 5s
if [ -f /etc/systemd/system.conf ]; then
  sed -i 's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
  sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf
fi

# Phase 2: Blacklist Legacy Drivers to avoid probing delays
mkdir -p /etc/modprobe.d
echo -e "blacklist floppy\nblacklist pcspkr\nblacklist parport\nblacklist parport_pc" > /etc/modprobe.d/agneax-blacklist.conf

# Phase 4: Quiet Sysctl Console Printk & Udev Suppressions
mkdir -p /etc/sysctl.d
echo "kernel.printk = 3 3 3 3" > /etc/sysctl.d/99-silent-boot.conf
if [ -f /etc/udev/udev.conf ]; then
  sed -i 's/#udev_log="info"/udev_log="err"/g' /etc/udev/udev.conf
  sed -i 's/udev_log="info"/udev_log="err"/g' /etc/udev/udev.conf
fi

# Phase 5: Optimized PAM Autologin Pipeline (Bypass Keyring load times)
if [ -f /etc/pam.d/lightdm-autologin ]; then
  sed -i 's/^auth[[:space:]]*optional[[:space:]]*pam_gnome_keyring.so/# auth optional pam_gnome_keyring.so/g' /etc/pam.d/lightdm-autologin
  sed -i 's/^session[[:space:]]*optional[[:space:]]*pam_gnome_keyring.so[[:space:]]*auto_start/# session optional pam_gnome_keyring.so auto_start/g' /etc/pam.d/lightdm-autologin
  sed -i 's/^session[[:space:]]*optional[[:space:]]*pam_kwallet5.so[[:space:]]*auto_start/# session optional pam_kwallet5.so auto_start/g' /etc/pam.d/lightdm-autologin
fi

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
if [ -f "packages/agneax_shell/cpp_src/build/libcompositor_helper.so" ]; then
  cp "packages/agneax_shell/cpp_src/build/libcompositor_helper.so" "$ROOTFS/usr/lib/libcompositor_helper.so"
  echo "C++ Layout Helper installed successfully."
fi

# Copy desktop and applications code
mkdir -p "$ROOTFS/opt/agneax/desktop"
mkdir -p "$ROOTFS/opt/agneax/control-center"
mkdir -p "$ROOTFS/opt/agneax/installer"
mkdir -p "$ROOTFS/opt/agneax/branding"

cp -R packages/agneax_shell/* "$ROOTFS/opt/agneax/desktop/" || true
cp -R control-center/* "$ROOTFS/opt/agneax/control-center/" || true
cp -R installer/* "$ROOTFS/opt/agneax/installer/" || true
cp -R branding/* "$ROOTFS/opt/agneax/branding/" || true

# Copy complete maui-shell source code for reference and developer customization
echo "Copying complete maui-shell source code into rootfs..."
mkdir -p "$ROOTFS/opt/agneax/agneax-shell-source"
cp -R packages/agneax-shell-source/* "$ROOTFS/opt/agneax/agneax-shell-source/" || true
rm -rf "$ROOTFS/opt/agneax/agneax-shell-source/.git"

# Package the Agneax Store from local source dynamically (Step 5 of analysis)
echo "Packaging Agneax Store dynamically from current workspace sources..."
chmod +x ./scripts/package_store.sh
./scripts/package_store.sh

# Generate PNG wallpaper from SVG vector for GRUB background (Step 2)
echo "Generating PNG wallpaper and text-based boot logo..."
rsvg-convert -w 1920 -h 1080 branding/wallpaper.svg -o build/wallpaper.png || echo "Warning: Failed to generate wallpaper PNG using rsvg-convert"

python3 -c '
try:
    from PIL import Image, ImageDraw, ImageFont
    
    # Render Text-based Boot Logo ("Agnea" in white, "X" in orange)
    img = Image.new("RGBA", (380, 96), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Try to load DejaVuSans-Bold or fallback to load_default
    font = None
    font_paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
        "DejaVuSans-Bold.ttf"
    ]
    for p in font_paths:
        try:
            font = ImageFont.truetype(p, 36)
            break
        except Exception:
            continue
            
    if font is None:
        font = ImageFont.load_default()
        
    # Get layout widths
    try:
        bbox_agnea = draw.textbbox((0, 0), "Agnea", font=font)
        w_agnea = bbox_agnea[2] - bbox_agnea[0]
        h_agnea = bbox_agnea[3] - bbox_agnea[1]
        
        bbox_x = draw.textbbox((0, 0), "X", font=font)
        w_x = bbox_x[2] - bbox_x[0]
    except AttributeError:
        w_agnea, h_agnea = draw.textsize("Agnea", font=font)
        w_x, _ = draw.textsize("X", font=font)
        
    total_w = w_agnea + w_x
    start_x = (380 - total_w) // 2
    start_y = (96 - h_agnea) // 2 - 4
    
    # Draw "Agnea" in White
    draw.text((start_x, start_y), "Agnea", fill=(255, 255, 255, 255), font=font)
    
    # Draw "X" in Premium Bright Orange (#FF6600)
    draw.text((start_x + w_agnea, start_y), "X", fill=(255, 102, 0, 255), font=font)
    
    img.save("build/logo.png")
    print("Text-based boot logo generated successfully using Pillow.")
except Exception as e:
    print(f"Warning: Failed to generate PNG assets using Pillow: {e}")
' || true

# Install Agneax Store Debian Package (Step 7)
cp "build/agneax-store_1.0.0_amd64.deb" "$ROOTFS/tmp/"
chroot "$ROOTFS" dpkg -i /tmp/agneax-store_1.0.0_amd64.deb || true
rm -f "$ROOTFS/tmp/agneax-store_1.0.0_amd64.deb"

# Install Custom Branded Plymouth Package (deep C customizations)
if [ -f "build/agneax-plymouth_1.0.0_amd64.deb" ]; then
  echo "Installing custom branded Plymouth package..."
  cp "build/agneax-plymouth_1.0.0_amd64.deb" "$ROOTFS/tmp/"
  chroot "$ROOTFS" dpkg -i /tmp/agneax-plymouth_1.0.0_amd64.deb || true
  rm -f "$ROOTFS/tmp/agneax-plymouth_1.0.0_amd64.deb"
else
  echo "Warning: build/agneax-plymouth_1.0.0_amd64.deb not found. Skipping compilation installer fallback."
fi

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
  
  # Colorize Plymouth spinner frames to Agneax Cyan (#00F2FE) using Pillow (Step 2)
  echo "Colorizing Plymouth spinner frames to match Agneax branding..."
  python3 -c '
from PIL import Image
import glob
import os

spinner_dir = "'"$ROOTFS"'/usr/share/plymouth/themes/spinner"
for filepath in glob.glob(os.path.join(spinner_dir, "spinner-*.png")):
    try:
        img = Image.open(filepath).convert("RGBA")
        datas = img.getdata()
        new_data = []
        for item in datas:
            if item[3] > 0:
                new_data.append((0, 242, 254, item[3]))
            else:
                new_data.append(item)
        img.putdata(new_data)
        img.save(filepath)
    except Exception as e:
        print(f"Error colorizing {filepath}: {e}")
print("Plymouth spinner frames colorized successfully.")
' || true
fi

# Integrate custom branded SDDM agneax theme from local packages
echo "Integrating custom branded SDDM agneax theme..."
mkdir -p "$ROOTFS/usr/share/sddm/themes/agneax"
cp -r packages/agneax-sddm-theme/* "$ROOTFS/usr/share/sddm/themes/agneax/"

# Copy custom Agneax wallpaper to SDDM theme
if [ -f "build/wallpaper.png" ]; then
  mkdir -p "$ROOTFS/usr/share/sddm/themes/agneax/Backgrounds"
  cp "build/wallpaper.png" "$ROOTFS/usr/share/sddm/themes/agneax/Backgrounds/agneax-wallpaper.png"
fi

# Copy configs (lightdm, network, rules)
cp -R configs/* "$ROOTFS/" || true

# Configure startup run script inside rootfs (Step 4 of analysis)
cat <<'EOF' > "$ROOTFS/opt/agneax/desktop/run.sh"
#!/usr/bin/env bash
# Startup script for Agneax Desktop environment
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export QT_WAYLAND_SHELL_INTEGRATION=kiosk-shell

# Display scaling & HiDPI (Component 2)
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_ENABLE_HIGHDPI_SCALING=1

# VSync & Double Buffering (Component 3)
export QMNG_FORCE_DOUBLE_BUFFER=1
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# GPU Texture Atlasing (Component 4 - Performance Caching)
export QSG_ATLAS_WIDTH=2048
export QSG_ATLAS_HEIGHT=2048

# X11 Shared-Memory Fallback parameters (Component 5)
export QT_X11_NO_MITSHM=1

if [ "$QT_QPA_PLATFORM" = "wayland" ]; then
    export QSG_RENDER_LOOP="${QSG_RENDER_LOOP:-threaded}"
else
    export QSG_RENDER_LOOP="${QSG_RENDER_LOOP:-basic}"
fi

cd /opt/agneax/desktop
python3 main.py >> /tmp/agneax-desktop.log 2>&1
EOF
chmod +x "$ROOTFS/opt/agneax/desktop/run.sh"

# Update initramfs inside chroot to apply zstd compression and include the new Plymouth logo
echo "Regenerating initramfs inside chroot..."
chroot "$ROOTFS" update-initramfs -u -k all

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
set timeout=1

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
    linux /live/vmlinuz boot=live union=overlay quiet splash loglevel=3 rd.systemd.show_status=false rd.udev.log_level=3 vt.global_cursor_default=0 squashfs.threads=0 live-media-timeout=15 ---
    initrd /live/initrd
}

menuentry "Agneax OS (Safe Graphics Mode)" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live union=overlay nomodeset loglevel=7 squashfs.threads=0 live-media-timeout=15 ---
    initrd /live/initrd
}

menuentry "Agneax OS Debug Console" {
    search --set=root --file /live/vmlinuz
    linux /live/vmlinuz boot=live union=overlay systemd.unit=multi-user.target loglevel=7 squashfs.threads=0 live-media-timeout=15 ---
    initrd /live/initrd
}
EOF

# Create BIOS and EFI bootable hybrid ISO
echo "Generating bootable hybrid ISO with grub-mkrescue..."
grub-mkrescue -o "$ISO_OUT/agneax-os-amd64.iso" "$IMAGE"

echo "=== Agneax OS ISO Build Complete! ==="
echo "Output path: $ISO_OUT/agneax-os-amd64.iso"
