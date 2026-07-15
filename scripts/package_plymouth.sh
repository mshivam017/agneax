#!/bin/bash
set -e

echo "=== Packaging Custom Branded Plymouth for Agneax OS ==="

# Define directories
BUILD_ROOT="build"
PKG_DIR="$BUILD_ROOT/package_plymouth"
SRC_CACHE="plymouth-src"
OUT_DEB="$BUILD_ROOT/agneax-plymouth_1.0.0_amd64.deb"

# Clean up past build files
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"

# 1. Verification of local source folder
if [ ! -d "$SRC_CACHE" ]; then
  echo "Error: local source folder $SRC_CACHE not found! Run git clone or checkout first."
  exit 1
fi

# 2. Configure and Compile Plymouth on the host using local modified source folder
cd "$SRC_CACHE"
echo "Running meson setup..."
# Configure prefix, libdir, and disable GTK/Docs/Tracing to keep package lightweight and fast.
# Force default boot splash backgrounds to pure pitch black (0x000000).
meson setup build \
  --prefix=/usr \
  --libdir=lib/x86_64-linux-gnu \
  -Dlogo=/usr/share/plymouth/themes/spinner/watermark.png \
  -Dudev=true \
  -Dgtk=disabled \
  -Ddocs=false \
  -Dtracing=false \
  -Dbackground-color=0x000000 \
  -Dbackground-start-color-stop=0x000000 \
  -Dbackground-end-color-stop=0x000000 \
  --buildtype=release \
  --wipe || meson setup build \
  --prefix=/usr \
  --libdir=lib/x86_64-linux-gnu \
  -Dlogo=/usr/share/plymouth/themes/spinner/watermark.png \
  -Dudev=true \
  -Dgtk=disabled \
  -Ddocs=false \
  -Dtracing=false \
  -Dbackground-color=0x000000 \
  -Dbackground-start-color-stop=0x000000 \
  -Dbackground-end-color-stop=0x000000 \
  --buildtype=release

echo "Compiling with ninja..."
ninja -C build
cd ..

# 4. Install compiled binaries into Debian package staging folder
echo "Staging Plymouth binaries for packaging..."
DESTDIR="$PWD/$PKG_DIR" ninja -C "$SRC_CACHE/build" install

# Remove unnecessary documentation and header files to keep package lightweight
rm -rf "$PKG_DIR/usr/include"
rm -rf "$PKG_DIR/usr/share/man"
rm -rf "$PKG_DIR/usr/lib/x86_64-linux-gnu/pkgconfig"

# 5. Create Debian package control configuration
cat <<EOT > "$PKG_DIR/DEBIAN/control"
Package: agneax-plymouth
Version: 1.0.0
Architecture: amd64
Maintainer: Agneax OS Team <mshivam017@github.com>
Provides: plymouth, plymouth-themes
Conflicts: plymouth, plymouth-themes
Replaces: plymouth, plymouth-themes
Depends: libc6, libdrm2, libgbm1, libpng16-16, libudev1, libpango-1.0-0, libcairo2
Description: Custom Branded Boot Splash for Agneax OS.
 Fast, flicker-free, 60FPS graphical boot splash screen.
 Fully replaces standard plymouth packaging with branding parameters.
EOT

# 6. Build the custom Debian Package
echo "Building debian package with dpkg-deb..."
dpkg-deb --build "$PKG_DIR" "$OUT_DEB"

echo "=== Custom agneax-plymouth_1.0.0_amd64.deb built successfully! ==="
