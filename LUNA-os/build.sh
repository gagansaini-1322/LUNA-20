#!/bin/sh
set -e
cd "$(dirname "$0")"
sudo lb clean --all
sudo lb config
sudo lb build 2>&1 | tee build.log
