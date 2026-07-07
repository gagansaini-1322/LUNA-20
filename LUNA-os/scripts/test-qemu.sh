#!/bin/bash
set -e

# LUNA OS QEMU Test Script
# This script tests the ISO in QEMU

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$SCRIPT_DIR/../out"

echo "=== LUNA OS QEMU Test ==="

# Find the ISO file
ISO=$(ls "$ISO_DIR"/*.iso 2>/dev/null | head -n1)

if [ -z "$ISO" ]; then
    echo "ERROR: No ISO found in $ISO_DIR"
    echo "Please build the ISO first with: ./build.sh"
    exit 1
fi

echo "Testing ISO: $ISO"
echo ""

# Check if QEMU is installed
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "ERROR: QEMU is not installed"
    echo "Install with: sudo pacman -S qemu-system-x86"
    exit 1
fi

# Check for OVMF (UEFI firmware)
OVMF_CODE="/usr/share/OVMF/OVMF_CODE_4M.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS_4M.fd"

if [ ! -f "$OVMF_CODE" ]; then
    echo "WARNING: OVMF not found, testing in BIOS mode only"
    echo "Install with: sudo pacman -S edk2-ovmf"
fi

# Create temporary vars file
TEMP_VARS=$(mktemp /tmp/OVMF_VARS.XXXXXX.fd)
cp "$OVMF_VARS" "$TEMP_VARS" 2>/dev/null || true

echo "Starting QEMU..."
echo "Press Ctrl+A then X to exit"
echo ""

# Run QEMU with UEFI support
if [ -f "$OVMF_CODE" ]; then
    qemu-system-x86_64 \
        -machine type=q35 -m 4096 -smp 4 \
        -enable-kvm -cpu host \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
        -drive if=pflash,format=raw,file="$TEMP_VARS" \
        -cdrom "$ISO" -boot d \
        -vga virtio \
        -display gtk,gl=on \
        -usb -device usb-tablet
else
    qemu-system-x86_64 \
        -machine type=q35 -m 4096 -smp 4 \
        -enable-kvm -cpu host \
        -cdrom "$ISO" -boot d \
        -vga virtio \
        -display gtk,gl=on \
        -usb -device usb-tablet
fi

# Cleanup
rm -f "$TEMP_VARS"

echo ""
echo "=== Test Complete ==="
