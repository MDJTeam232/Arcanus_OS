#!/usr/bin/env bash
set -euo pipefail

# Updated usage to allow choosing architecture (defaults to x86_64)
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <image-or-iso-or-tar> [x86_64|arm64]" >&2
  exit 2
fi

SOURCE="$1"
ARCH="${2:-x86_64}" # Defaults to x86_64 if not explicitly provided
TARGET_DIR="dist"

if [[ ! -f "$SOURCE" ]]; then
  echo "Artifact not found: $SOURCE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

# Dynamically route the artifact name based on architecture and extension
case "$SOURCE" in
  *.iso) 
    TARGET="$TARGET_DIR/ArcanusOS-Alpha-$ARCH.iso" 
    ;;
  *.img.xz) 
    TARGET="$TARGET_DIR/ArcanusOS-Alpha-$ARCH.img.xz" 
    ;;
  *.img) 
    TARGET="$TARGET_DIR/ArcanusOS-Alpha-$ARCH.img" 
    ;;
  *.tar.gz|*.tgz|*.tar.xz) 
    TARGET="$TARGET_DIR/ArcanusOS-Alpha-$ARCH-rootfs.tar.gz" 
    ;;
  *) 
    TARGET="$TARGET_DIR/ArcanusOS-Alpha-$ARCH.artifact" 
    ;;
esac

cp "$SOURCE" "$TARGET"
echo "Successfully packaged: $TARGET"
