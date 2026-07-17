#!/usr/bin/env bash
# Install host dependencies required to compile Agneax OS components and build the live ISO.
# This script should be run with sudo on Ubuntu/Debian.

set -e

echo "=== Installing Host Dependencies for Agneax OS Build ==="

if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run as root (sudo)"
  exit 1
fi

# Update system repositories
apt-get update

# Install build dependencies
apt-get install -y \
  debootstrap \
  xorriso \
  squashfs-tools \
  mtools \
  grub-pc-bin \
  grub-efi-amd64-bin \
  grub-efi-ia32-bin \
  cmake \
  build-essential \
  libgl1-mesa-dev \
  libegl1-mesa-dev \
  libwayland-dev \
  libx11-dev \
  libxkbcommon-dev \
  python3 \
  python3-pip \
  curl

# Install Rust toolchain if not present
if ! command -v cargo &> /dev/null; then
  echo "Rust not found. Installing via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  echo "Rust (cargo) is already installed."
fi

echo "Dependencies installation completed successfully!"
