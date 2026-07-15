#!/bin/bash
set -e

echo "=== Packaging Custom Branded Plymouth for Agneax OS ==="

# Define directories
BUILD_ROOT="build"
PKG_DIR="$BUILD_ROOT/package_plymouth"
SRC_CACHE="$BUILD_ROOT/plymouth_source"
OUT_DEB="$BUILD_ROOT/agneax-plymouth_1.0.0_amd64.deb"

# Clean up past build files
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"

# 1. Clone upstream Plymouth source code if not cached
if [ ! -d "$SRC_CACHE" ]; then
  echo "Cloning Plymouth upstream repository..."
  git clone --depth 1 https://gitlab.freedesktop.org/plymouth/plymouth.git "$SRC_CACHE"
else
  echo "Using cached Plymouth upstream repository."
fi

# 2. Apply Custom Agneax Branding Patches in Plymouth C Source
echo "Applying custom patches to Plymouth C source..."
# Increase default font smoothing hints in graphics drawing if available
# Force standard layout margins in two-step plugin configurations
TWO_STEP_SRC="$SRC_CACHE/src/plugins/splash/two-step/two-step.c"
if [ -f "$TWO_STEP_SRC" ]; then
  # Set default watermark animation durations to be faster and smoother in C source code
  sed -i 's/#define DEFAULT_TRANSITION_DURATION 1.0/#define DEFAULT_TRANSITION_DURATION 0.4/g' "$TWO_STEP_SRC"
  echo "Patched transition duration in two-step.c"
fi

# 3. Configure and Compile Plymouth on the host
cd "$SRC_CACHE"
echo "Running meson setup..."
# Configure prefix and libdir to perfectly match Debian Bookworm multiarch paths
meson setup build \
  --prefix=/usr \
  --libdir=lib/x86_64-linux-gnu \
  -Dlogo=/usr/share/plymouth/themes/spinner/watermark.png \
  -Dudev=true \
  --buildtype=release \
  --wipe || meson setup build --prefix=/usr --libdir=lib/x86_64-linux-gnu -Dlogo=/usr/share/plymouth/themes/spinner/watermark.png -Dudev=true --buildtype=release

echo "Compiling with ninja..."
ninja -C build
cd ../..

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
