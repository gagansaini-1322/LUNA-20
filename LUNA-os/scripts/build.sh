#!/bin/bash
set -e

# LUNA OS Build Script
# This script builds the LUNA OS ISO using archiso

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$SCRIPT_DIR/../configs/lunaos"
WORK_DIR="/tmp/lunaos-work"
OUT_DIR="$SCRIPT_DIR/../out"

echo "=== LUNA OS Build Script ==="
echo "Profile: $PROFILE_DIR"
echo "Work: $WORK_DIR"
echo "Output: $OUT_DIR"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

# Check if archiso is installed
if ! command -v mkarchiso &> /dev/null; then
    echo "ERROR: archiso is not installed"
    echo "Install with: sudo pacman -S archiso"
    exit 1
fi

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$WORK_DIR"
rm -rf "$OUT_DIR"

# Build the ISO
echo "Building LUNA OS ISO..."
mkarchiso -v -r -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

echo ""
echo "=== Build Complete ==="
echo "ISO location: $OUT_DIR"
ls -la "$OUT_DIR"/*.iso 2>/dev/null || echo "No ISO found"
