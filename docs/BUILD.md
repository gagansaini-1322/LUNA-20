# Building LUNA OS

This guide explains how to build LUNA OS from source.

## Prerequisites

### On Arch Linux

```bash
# Install archiso
sudo pacman -S archiso

# Install additional tools
sudo pacman -S git base-devel
```

### On Other Distros

You can use Docker or a VM running Arch Linux to build.

## Build Instructions

### Quick Build

```bash
# Clone the repository
git clone https://github.com/lunaos/lunaos.git
cd lunaos

# Build the ISO
sudo ./LUNA-os/scripts/build.sh
```

### Manual Build

```bash
# Navigate to the profile directory
cd LUNA-os/configs/lunaos

# Build with mkarchiso
sudo mkarchiso -v -r -w /tmp/lunaos-work -o /tmp/lunaos-out .

# The ISO will be in /tmp/lunaos-out/
ls -la /tmp/lunaos-out/*.iso
```

## Testing

### Test in QEMU

```bash
./LUNA-os/scripts/test-qemu.sh
```

### Test on Real Hardware

1. Write the ISO to a USB drive:
```bash
sudo dd if=lunaos-*.iso of=/dev/sdX bs=4M status=progress
```

2. Boot from USB
3. Test the live environment
4. Use Calamares to install to disk

## Project Structure

```
LUNA-os/
├── configs/
│   └── lunaos/           # Archiso profile
│       ├── profiledef.sh # ISO metadata
│       ├── packages.x86_64  # Package list
│       ├── pacman.conf   # Build-time pacman config
│       └── airootfs/     # Root filesystem overlay
├── scripts/
│   ├── build.sh          # Build script
│   └── test-qemu.sh      # QEMU test script
├── docs/
│   ├── BUILD.md          # This file
│   └── INSTALLATION.md   # Installation guide
└── README.md
```

## Customization

### Adding Packages

Edit `LUNA-os/configs/lunaos/packages.x86_64` to add or remove packages.

### Changing Branding

Branding files are in `LUNA-os/configs/lunaos/airootfs/usr/share/`:
- `plymouth/themes/lunaos/` - Boot splash
- `sddm/themes/lunaos/` - Login screen
- `plasma/look-and-feel/lunaos.desktop/` - KDE theme
- `color-schemes/` - Color schemes
- `wallpapers/lunaos/` - Wallpapers

### Calamares Configuration

Installer configuration is in:
`LUNA-os/configs/lunaos/airootfs/etc/calamares/`

## Troubleshooting

### Build Fails

1. Ensure you're running as root: `sudo ./build.sh`
2. Check that archiso is installed: `pacman -S archiso`
3. Clean previous builds: `rm -rf /tmp/lunaos-work`

### ISO Won't Boot

1. Verify the ISO was created successfully
2. Try a different USB drive
3. Check BIOS/UEFI settings
4. Test in QEMU first

### Missing Packages

1. Check the package list in `packages.x86_64`
2. Ensure multilib repository is enabled in `pacman.conf`
3. Some packages may be in AUR (not included by default)

## CI/CD

The GitHub Actions workflow (`.github/workflows/Build.yml`) automatically:
1. Builds the ISO on every push to main
2. Tests boot in QEMU
3. Uploads the ISO as an artifact

## Links

- Arch Wiki - Archiso: https://wiki.archlinux.org/title/Archiso
- LUNA OS Website: https://lunaos.org
