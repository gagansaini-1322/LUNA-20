#!/bin/bash
set -e

# LUNA OS - Build-time customization script
# This script runs inside the chroot during ISO build

echo "=== LUNA OS Build customization ==="

# Configure locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

# Set hostname
echo "lunaos" > /etc/hostname

# Enable services for live session
systemctl enable NetworkManager.service
systemctl enable sddm.service
systemctl enable plymouth-start.service
systemctl enable plymouth-quit.service
systemctl enable bluetooth.service

# Configure Plymouth
plymouth-set-default-theme -R lunaos

# Gaming optimizations
echo "vm.max_map_count=2147483642" > /etc/sysctl.d/80-gamecompat.conf

# Create live user (for live session)
useradd -m -G wheel,video,audio,storage,NetworkManager -s /bin/bash liveuser
echo "liveuser:live" | chpasswd

# Enable sudo for wheel group
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Set default target to graphical
systemctl set-default graphical.target

# Configure pacman for live session
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# Clean up
rm -rf /var/cache/pacman/pkg/*
rm -rf /tmp/*

echo "=== LUNA OS Build customization complete ==="
