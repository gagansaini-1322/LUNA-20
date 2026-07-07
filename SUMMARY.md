# LUNA OS - Session Summary

## Objective
- Build **LUNA OS**: a lightweight Arch-based gaming Linux distribution (KDE Plasma + Steam/Lutris/Wine + GameMode/MangoHud) with BIOS (syslinux) + UEFI (systemd-boot) boot, Plymouth, custom branding, and GitHub Actions CI/CD that produces a bootable ISO.

## Repository
- Repo: `https://github.com/gagansaini-1322/LUNA_OS-2.0` (was `LUNA-20`, remote updated to new URL)
- Profile path: `LUNA-os/configs/lunaos/`
- Branch: `main`

## Key Configuration

### profiledef.sh
- `iso_name="lunaos"`
- `iso_label="LUNA_OS_2026"`
- `install_dir="luna"`
- `bootmodes=('bios.syslinux' 'uefi.systemd-boot')`  (updated from deprecated `bios.syslinux.mbr` / `uefi-x64.systemd-boot.esp`)
- `airootfs_image_type="squashfs"`
- `file_permissions` sets root script + shadow perms

### Boot entries (use archiso template vars)
- `%INSTALL_DIR%` → `luna`
- `%ARCH%` → `x86_64`
- `%ARCHISO_UUID%` → ISO UUID (the correct param for archiso initramfs hook)
- Kernel params: `archisobasedir=%INSTALL_DIR% archisosearchuuid=%ARCHISO_UUID% modules=loop,squashfs`
- **DO NOT** use `%ARCHISO_LABEL%` — it was tried, produced a non-matching search value, caused root-device emergency mode, then reverted.

### packages.x86_64
- Removed: `kde-utils` (group gone), `dxvk`, `lib32-dxvk`, `calamares` (AUR / not in official repos)
- `systemd-boot` package does NOT exist — `uefi.systemd-boot` boot mode auto-installs the EFI binary
- CI host needs: `archiso git dosfstools mtools`

### customize_airootfs.sh
- `useradd` uses groups `wheel,video,audio,storage` (removed `NetworkManager` — group doesn't exist at build time)
- Enables: NetworkManager, sddm, plymouth-start, plymouth-quit, bluetooth
- Sets Plymouth theme `lunaos`, game-compat sysctl, live user `liveuser` / password `live`
- Sets default target `graphical.target`

### CI workflow (.github/workflows/Build.yml)
- Container `archlinux:latest` with `--privileged` (mkarchiso needs to mount /proc)
- Installs `archiso git dosfstools mtools`
- Build step: `mkarchiso -v -r -w /tmp/lunaos-work -o /tmp/lunaos-out LUNA-os/configs/lunaos`
- QEMU smoke test with **dynamic OVMF path discovery** (`find /usr/share -name 'OVMF_CODE.fd'`)
- Upload ISO artifact: `if: always() && steps.build.outcome == 'success'`
- Upload build logs: `if: always()`

### .gitignore
- Ignores: `Screenshot*.png`, `*.zip`, `*.iso`, `mcps`

## Local Test Environment
- QEMU + OVMF: `/usr/share/OVMF/OVMF_CODE_4M.fd`, `/usr/share/OVMF/OVMF_VARS_4M.fd`
- noVNC: `/usr/share/novnc`, websockify bridges port **6080** → VNC **:5900**
- Command pattern:
  ```
  qemu-system-x86_64 -machine type=q35 -m 4096 -smp 4 -accel tcg -cpu max \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
    -drive if=pflash,format=raw,file=/tmp/OVMF_VARS.fd \
    -cdrom <iso> -boot d -vnc :0 -display none \
    -serial file:/tmp/serial.log -monitor none -no-reboot -daemonize
  websockify --web /usr/share/novnc 6080 localhost:5900
  ```
- noVNC external URL (needs Codespace port-forward auth):
  `https://<codespace>-6080.app.github.dev/vnc_auto.html`
  → open via **PORTS** tab → "Open in Browser"
- OVMF single VNC client limit: websockify holds the connection, so `vncdo` capture needs websockify killed briefly first.

## Chronicle of Fixes (commits)
1. Initial archiso profile commit + repo cleanup (removed old Debian live-build files)
2. Merge divergent remote, push to new repo URL
3. `fix: update boot modes and add missing syslinux/efiboot directories` — deprecated bootmodes + created `syslinux/syslinux.cfg` and `efiboot/loader/{loader.conf,entries/*.conf}`
4. `fix: add --privileged to container for mkarchiso mount support`
5. `fix: remove non-repo packages (kde-utils, dxvk, calamares)`
6. `fix: remove NetworkManager group from useradd`
7. `fix: find OVMF path dynamically, ensure ISO upload on build success`
8. `fix: use archiso template identifiers for UEFI/systemd-boot` — `%INSTALL_DIR%`/`%ARCH%`/`%ARCHISO_UUID%` in entries; `archisobasedir=%INSTALL_DIR%` in syslinux
9. `fix: restore archiso UUID placeholder for boot entries` — reverted `%ARCHISO_LABEL%` → `%ARCHISO_UUID%` (commit `d4dc69d`)
10. `.gitignore` + removed accidentally-committed `mcps` / screenshots

## Current Status (last verified)
- Build `28873498811` (commit `d4dc69d`) succeeded.
- ISO boots: systemd-boot menu shows "LUNA OS (x86_64, UEFI)" etc.
- Serial log shows **no** emergency-mode / `gpt-auto-root` / dependency-failed errors → root filesystem mounts correctly.
- Live VM is runnable via QEMU + noVNC on port 6080.

## Known Limitations / TODO
- `calamares`, `dxvk`, `lib32-dxvk` are AUR packages — need an AUR helper (yay) or post-install script if wanted.
- User wants to add custom apps later (deferred).
- `console=ttyS0` not added to boot params — serial only shows the UEFI menu, not kernel messages (graphical console gets them).
- vncdo screenshot capture requires killing websockify first (single VNC client limit).
