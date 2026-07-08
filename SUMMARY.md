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

### Boot entries (use archiso template vars — matches official releng profile)
- `%INSTALL_DIR%` → `luna` (substituted by mkarchiso at build time)
- `%ARCH%` → `x86_64` (substituted by mkarchiso at build time)
- `%ARCHISO_UUID%` → ISO 9660 modification date e.g. `2026-07-08-06-17-49-00` (substituted by mkarchiso at build time)
- Kernel params: `archisobasedir=%INSTALL_DIR% archisosearchuuid=%ARCHISO_UUID%`
- **DO NOT** use `archisolabel` — it relies on udev `/dev/disk/by-label/` symlinks which can fail on ISO media during early boot
- **DO NOT** use `modules=loop,squashfs` — not a valid archiso boot parameter, modules loaded automatically by the hook

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
- **UEFI smoke test** with dynamic OVMF path discovery
- **BIOS smoke test** with SeaBIOS — checks serial log for emergency/gpt-auto-root errors
- Upload ISO artifact: `if: always() && steps.build.outcome == 'success'`
- Upload build logs: `if: always()`

### .gitignore
- Ignores: `Screenshot*.png`, `*.zip`, `*.iso`, `mcps`

## Local Test Environment
- QEMU + OVMF: `/usr/share/OVMF/OVMF_CODE_4M.fd`, `/usr/share/OVMF/OVMF_VARS_4M.fd`
- noVNC: `/usr/share/novnc`, websockify bridges port **6080** → VNC **:5900`
- noVNC external URL (needs Codespace port-forward auth):
  `https://<codespace>-6080.app.github.dev/vnc_auto.html`
  → open via **PORTS** tab → "Open in Browser"

## Chronicle of Fixes (commits)
1. Initial archiso profile commit + repo cleanup (removed old Debian live-build files)
2. Merge divergent remote, push to new repo URL
3. `fix: update boot modes and add missing syslinux/efiboot directories` — deprecated bootmodes + created `syslinux/syslinux.cfg` and `efiboot/loader/{loader.conf,entries/*.conf}`
4. `fix: add --privileged to container for mkarchiso mount support`
5. `fix: remove non-repo packages (kde-utils, dxvk, calamares)`
6. `fix: remove NetworkManager group from useradd`
7. `fix: find OVMF path dynamically, ensure ISO upload on build success`
8. `fix: use archiso template identifiers for UEFI/systemd-boot` — `%INSTALL_DIR%`/`%ARCH%`/`%ARCHISO_UUID%` in entries
9. `fix: restore archiso UUID placeholder for boot entries` — reverted `%ARCHISO_LABEL%` → `%ARCHISO_UUID%`
10. `.gitignore` + removed accidentally-committed `mcps` / screenshots
11. **`fix: hardcode ISO label in syslinux`** — changed `%ARCHISO_LABEL%` to hardcoded `LUNA_OS_2026` (syslinux doesn't substitute template vars)
12. **`fix: use archisosearchuuid=%ARCHISO_UUID% for reliable BIOS/UEFI boot`** — switched from `archisolabel` to `archisosearchuuid` matching official archiso releng profile; removed invalid `modules=loop,squashfs`; added BIOS QEMU smoke test to CI

## Current Status (last verified — build `28921931132`, commit `b4862c7`)
- **Build**: CI passes (ISO built, both UEFI + BIOS QEMU smoke tests ran)
- **UEFI boot**: systemd-boot menu shows "LUNA OS (x86_64, UEFI)" with 3 entries, auto-boots after 5s countdown, VM runs successfully
- **BIOS boot**: ISOLINUX loads kernel + initramfs successfully ("ok"), kernel starts (Probing EDD), **zero emergency/gpt-auto-root/timed-out errors** in serial log
- **Configs verified**: ISO contents show correctly substituted params (`archisosearchuuid=2026-07-08-06-17-49-00`)
- `console=ttyS0` not in boot cmdline — kernel output not visible on serial (graphical console gets it), which is normal for archiso

## Known Limitations / TODO
- `calamares`, `dxvk`, `lib32-dxvk` are AUR packages — need an AUR helper (yay) or post-install script if wanted
- User wants to add custom apps later (deferred)
- `console=ttyS0` not added to boot params — serial only shows boot loader menus, not kernel messages (graphical console gets them)
