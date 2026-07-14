# Agneax OS — Installation Guide

This document describes the process of deploying and configuring Agneax OS on bare-metal systems, virtualization systems, and dual-boot configurations.

---

## 1. System Requirements

Ensure the target system meets these parameters:
- **RAM**: Minimum 4 GB, Recommended 8 GB (for virtualization/AI suites).
- **Storage Space**: Minimum 32 GB SSD/HDD, Recommended 128 GB NVMe.
- **CPU**: Intel/AMD 64-bit dual-core, Recommended quad-core.
- **Firmware**: UEFI (Secure Boot compatible) or Legacy BIOS support.

---

## 2. Preparing Boot Media

1. Download the bootable release ISO: `agneax-os-amd64.iso`.
2. Flash to a USB drive using `dd` on Linux/macOS or Rufus on Windows:
   ```bash
   sudo dd if=agneax-os-amd64.iso of=/dev/sdX bs=4M status=progress oflag=sync
   ```

---

## 3. Partition Layout Recommendations

Agneax Installer supports automatic and manual partition structures.

### A. Automatic Partitioning
Configures a standard modern layout automatically:
1. **Partition 1 (EFI System Partition)**: 512 MB, FAT32 format, mount: `/boot/efi`, boot flag enabled.
2. **Partition 2 (System Rootfs)**: Remainder space, ext4 or Btrfs format, mount: `/`.
3. **Partition 3 (Linux Swap)**: 4 GB, swap space partition.

### B. Manual Partitioning (Dual Boot Setup)
If installing alongside Windows or other Linux operating systems:
1. Allocate at least 30 GB of unallocated disk space on the drive.
2. Create an `ext4` partition on this workspace. Set mount point to `/`.
3. Use the existing Windows EFI system partition as the mount target for `/boot/efi` without formatting it to preserve Windows bootloaders.

---

## 4. LUKS Full Disk Encryption (LUKS2)
To secure personal data:
- Toggle **Encrypt Agneax installation drive (LUKS)** on the partition page.
- Choose a robust passphrase. The installer will format the `/` partition as an encrypted LUKS container, prompting for credentials on startup before mounting the root directories.
