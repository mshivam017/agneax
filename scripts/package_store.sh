#!/bin/bash
set -e

echo "=== Packaging Agneax Store as Debian Package ==="

# Define workspace directory paths
PKG_DIR="build/package_store"
OUT_DIR="build"

# Clean previous outputs
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/opt/agneax/store/qml"

# 1. Create control file
cat <<EOT > "$PKG_DIR/DEBIAN/control"
Package: agneax-store
Version: 1.0.0
Architecture: amd64
Maintainer: Agneax OS Team <mshivam017@github.com>
Depends: python3, python3-pip, libgl1-mesa-dri, libxkbcommon-x11-0, libxcb-cursor0
Description: Unified App Hub for Agneax OS.
 High-speed GUI software store interface supporting APT, Flatpak, and AppImage.
 Includes screenshots and user reviews layout.
EOT

# 2. Create the executable binary shell launcher wrapper
cat <<EOT > "$PKG_DIR/usr/bin/agneax-store"
#!/bin/bash
python3 /opt/agneax/store/main.py "\$@"
EOT
chmod +x "$PKG_DIR/usr/bin/agneax-store"

# 3. Create desktop launcher shortcut
cat <<EOT > "$PKG_DIR/usr/share/applications/agneax-store.desktop"
[Desktop Entry]
Name=Agneax Store
Comment=Manage and Install Software Apps
Exec=agneax-store
Icon=system-software-install
Terminal=false
Type=Application
Categories=System;Settings;PackageManager;
EOT

# 4. Copy code files from workspace to package folder paths
cp store/main.py "$PKG_DIR/opt/agneax/store/"
cp store/qml/Store.qml "$PKG_DIR/opt/agneax/store/qml/"

# 5. Build the debian package
echo "Running dpkg-deb --build..."
dpkg-deb --build "$PKG_DIR" "$OUT_DIR/agneax-store_1.0.0_amd64.deb"

echo "=== Debian package agneax-store_1.0.0_amd64.deb successfully built! ==="
