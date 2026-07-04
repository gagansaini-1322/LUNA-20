# Luna OS

**Light. Fast. Limitless.**

A custom Ubuntu Noble (24.04 LTS) based live ISO built with live-build, featuring
a complete custom GTK3 desktop replacement.

* Custom dark GTK3 theme for XFCE
* Glassmorphic bottom dock (custom-built, no Plank/Cairo-Dock)
* Full-width top bar with workspace switcher, indicators, performance mode
* Luna Hub — Flask + WebKit2 system monitor
* Luna Settings — centered window with macOS-style controls
* Plymouth video-based boot animation (94 frames, two-step module)
* 9 genre wallpapers (FPS, RPG, Racing, Strategy, Platformer, Retro/Emulation, etc.)
* Steam + luatools-moon Lua mods pre-staged
* Auto-login as `user` (password `luna`)

## Build

```bash
sudo apt-get install -y \
    live-build xorriso isolinux syslinux-common \
    debootstrap squashfs-tools bc

# Build
sudo ./build.sh         # local
# OR
gh workflow run Build.yml   # GitHub Actions
```

The resulting ISO lands at `LUNA-os/*.iso`.

## Test in QEMU

```bash
sudo chmod 666 /dev/kvm
qemu-system-x86_64 -enable-kvm -cpu host -m 4G -cdrom LUNA-os/*.iso -boot d -vnc :1
```

## Layout

```
LUNA-os/
├── auto/{config,build}        ← live-build entrypoints
├── config/
│   ├── hooks/*.hook.chroot    ← build-time chroot hooks
│   ├── includes.binary/       ← files added to ISO boot image
│   ├── includes.chroot/       ← filesystem overlay (becomes /)
│   └── package-lists/luna.list.chroot
└── ...
```

## Live user

* Username: `user`
* Password: `luna`
* Hostname: `luna`
