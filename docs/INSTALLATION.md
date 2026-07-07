# Installing LUNA OS

This guide explains how to install LUNA OS to your computer or USB drive.

## Requirements

- 64-bit x86 processor
- 4 GB RAM (recommended)
- 20 GB disk space (recommended)
- USB drive (8 GB or larger) for installation media

## Creating Installation Media

### On Linux

```bash
# Download the ISO
wget https://github.com/lunaos/lunaos/releases/latest/download/lunaos-*.iso

# Write to USB (replace /dev/sdX with your USB drive)
sudo dd if=lunaos-*.iso of=/dev/sdX bs=4M status=progress
sync
```

### On Windows

1. Download the ISO from GitHub Releases
2. Use [Rufus](https://rufus.ie/) or [Etcher](https://www.balena.io/etcher/)
3. Select the ISO file and your USB drive
4. Click "Flash"

### On macOS

1. Download the ISO from GitHub Releases
2. Use [Etcher](https://www.balena.io/etcher/)
3. Select the ISO file and your USB drive
4. Click "Flash"

## Booting from USB

1. Insert the USB drive
2. Restart your computer
3. Enter BIOS/UEFI setup (usually F2, F12, or Del)
4. Set USB as the first boot device
5. Save and exit

## Live Environment

When you boot from USB, you'll enter the LUNA OS live environment:

- **Desktop**: KDE Plasma with LUNA OS theme
- **Installer**: Calamares installer is available on the desktop
- **Username**: `liveuser`
- **Password**: `live`

You can try LUNA OS before installing.

## Installation

### Install to Internal Disk

1. Open Calamares installer (double-click on desktop)
2. Follow the wizard:
   - **Welcome**: Select your language
   - **Location**: Choose your timezone
   - **Keyboard**: Select your keyboard layout
   - **Partitions**: Choose installation type:
     - **Erase disk**: Automatic partitioning (recommended)
     - **Manual**: Custom partitioning
   - **Users**: Create your user account
   - **Summary**: Review your choices
   - **Install**: Begin installation
3. Wait for installation to complete
4. Restart your computer

### Install to USB (Persistent)

To create a persistent LUNA OS installation on USB:

1. Boot from the LUNA OS USB
2. Open Calamares installer
3. Select "Install to USB" option
4. Choose your USB drive as the target
5. Follow the installation steps

**Note**: This will erase all data on the target USB drive.

### Manual Installation

For advanced users, you can install manually:

```bash
# Partition your disk
fdisk /dev/sda

# Format partitions
mkfs.ext4 /dev/sda1  # root
mkswap /dev/sda2     # swap
mkfs.fat -F32 /dev/sda3  # EFI (if UEFI)

# Mount partitions
mount /dev/sda1 /mnt
swapon /dev/sda2
mount /dev/sda3 /mnt/boot/efi  # if UEFI

# Install base system
pacstrap /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into new system
arch-chroot /mnt

# Set timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "lunaos" > /etc/hostname

# Install bootloader
# For UEFI:
bootctl install
# For BIOS:
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

# Install desktop environment
pacman -S plasma-desktop sddm

# Enable SDDM
systemctl enable sddm

# Exit and reboot
exit
umount -R /mnt
reboot
```

## Post-Installation

### First Boot

1. Log in with your user account
2. SDDM will load the LUNA OS theme
3. KDE Plasma desktop will appear

### Gaming Setup

LUNA OS comes with gaming software pre-installed:

- **Steam**: Launch from application menu
- **Lutris**: Launch from application menu
- **MangoHud**: Use `mangohud %command%` in Steam launch options
- **GameMode**: Automatically enabled for supported games

### System Updates

```bash
# Update system
sudo pacman -Syu

# Update AUR packages (if using yay)
yay -Sua
```

## Troubleshooting

### Boot Issues

- **Black screen**: Try adding `nomodeset` to kernel parameters
- **No WiFi**: Ensure NetworkManager is running: `sudo systemctl start NetworkManager`
- **No sound**: Check PipeWire: `systemctl --user status pipewire`

### Installation Issues

- **Calamares won't open**: Check if you have enough disk space
- **Partition not showing**: Ensure the disk is unmounted
- **Bootloader fails**: Try installing GRUB manually

### Graphics Issues

- **NVIDIA**: Install `nvidia` and `nvidia-utils`
- **AMD**: Install `vulkan-radeon` and `mesa`
- **Intel**: Install `vulkan-intel` and `mesa`

## Links

- LUNA OS Website: https://lunaos.org
- Arch Wiki: https://wiki.archlinux.org
- GitHub: https://github.com/lunaos/lunaos
