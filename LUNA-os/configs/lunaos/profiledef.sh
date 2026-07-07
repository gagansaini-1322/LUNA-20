#!/usr/bin/env bash
# shellcheck disable=SC2034

# LUNA OS - Profile Definition
# Lightweight Arch-based Gaming Distribution

iso_name="lunaos"
iso_label="LUNA_OS_2026"
iso_publisher="LUNA OS Project"
iso_application="LUNA OS - Gaming Edition"
iso_version="$(date +%Y.%m.%d)"
install_dir="luna"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')

file_permissions=(
    ["/etc/shadow"]="0:0:0400"
    ["/etc/gshadow"]="0:0:0400"
    ["/root"]="0:0:0750"
    ["/root/customize_airootfs.sh"]="0:0:0755"
)
