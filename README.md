# LUNA OS

**Light. Fast. Limitless.**

A lightweight Arch-based gaming distribution with KDE Plasma desktop.

## Features

- **Gaming Ready**: Steam, Lutris, Wine pre-installed
- **Performance**: GameMode, MangoHud, Vulkan drivers
- **KDE Plasma**: Modern, customizable desktop environment
- **Arch Linux**: Rolling release, latest packages
- **Calamares Installer**: Easy installation to USB or internal disk

## Included Software

### Gaming
- Steam with Proton support
- Lutris game manager
- Wine for Windows games
- MangoHud performance overlay
- GameMode optimizations

### Desktop
- KDE Plasma desktop environment
- SDDM display manager
- Dolphin file manager
- Konsole terminal

### System
- PipeWire audio
- NetworkManager
- Plymouth boot splash

## Building from Source

### Prerequisites

- Arch Linux (or Arch-based distribution)
- `archiso` package installed

### Build

```bash
# Install archiso
sudo pacman -S archiso

# Build the ISO
sudo ./LUNA-os/scripts/build.sh
```

The ISO will be created in the `out/` directory.

### Test in QEMU

```bash
# Test the ISO
./LUNA-os/scripts/test-qemu.sh
```

## Installation

1. Download the ISO from GitHub Releases
2. Create a bootable USB using `dd` or Etcher
3. Boot from USB
4. Follow the Calamares installer

### Install to USB (Persistent)

1. Boot from USB
2. Open Calamares installer
3. Select "Install to USB" option
4. Choose your USB drive as target
5. Follow the installation steps

## Customization

### Wallpapers

LUNA OS includes 9 custom wallpapers in `/usr/share/wallpapers/lunaos/`

### Color Scheme

The default color scheme is "LUNA OS Dark" with blue accents.

### Plymouth Boot Splash

The LUNA OS Plymouth theme shows the logo during boot.

## Links

- Website: https://lunaos.org
- GitHub: https://github.com/lunaos/lunaos
- Issues: https://github.com/lunaos/lunaos/issues

## License

LUNA OS is open source software licensed under GPL-3.0.
