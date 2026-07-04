#!/bin/sh
# Luna OS — top-level build helper
# Requires: live-build (3.0~a57-1ubuntu49.1 or later)
set -e
cd "$(dirname "$0")/LUNA-os"
lb clean --all || true
lb config "$@"
lb build
