#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <image-or-iso>" >&2
  exit 2
fi

SOURCE="$1"
TARGET_DIR="dist"

if [[ ! -f "$SOURCE" ]]; then
  echo "Artifact not found: $SOURCE" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

case "$SOURCE" in
  *.iso) TARGET="$TARGET_DIR/ArcanusOS-Alpha-x86_64.iso" ;;
  *.img.xz) TARGET="$TARGET_DIR/ArcanusOS-Alpha-x86_64.img.xz" ;;
  *.img) TARGET="$TARGET_DIR/ArcanusOS-Alpha-x86_64.img" ;;
  *) TARGET="$TARGET_DIR/ArcanusOS-Alpha-x86_64.artifact" ;;
esac

cp "$SOURCE" "$TARGET"
echo "$TARGET"
