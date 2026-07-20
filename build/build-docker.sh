#!/usr/bin/env bash
# Build Arcanus OS Alpha ISO inside Docker (works from macOS).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_NAME="${ARCANUS_ISO_IMAGE:-arcanus-os-iso-builder:local}"
CACHE_DIR="$REPO_ROOT/.cache/iso"
DIST_DIR="$REPO_ROOT/dist"
# Scratch lives on a Linux Docker volume (not a macOS bind mount).
# unsquashfs must create device nodes; host/osxfs mounts reject that with EPERM.
BUILD_VOLUME="${ARCANUS_BUILD_VOLUME:-arcanus-iso-build}"

log() {
  printf '[arcanus-docker] %s\n' "$*"
}

fail() {
  printf '[arcanus-docker] ERROR: %s\n' "$*" >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker is required"

if ! docker info >/dev/null 2>&1; then
  fail "docker daemon is not running (open Docker Desktop, then retry)"
fi

install -d "$CACHE_DIR" "$DIST_DIR"

# Mint rootfs is x86_64; force amd64 even on Apple Silicon.
PLATFORM="${DOCKER_PLATFORM:-linux/amd64}"

log "Building Docker image: $IMAGE_NAME ($PLATFORM)"
docker build \
  --platform "$PLATFORM" \
  -t "$IMAGE_NAME" \
  -f "$REPO_ROOT/build/Dockerfile.iso" \
  "$REPO_ROOT/build"

# Linux Mint ISO remaster needs privileged for mount/chroot.
# Cache the upstream ISO on the host so rebuilds do not re-download ~3GB.
# Build workspace uses a named volume so device nodes and chroot work on macOS.
DOCKER_TTY=()
if [[ -t 0 && -t 1 ]]; then
  DOCKER_TTY=(-it)
else
  DOCKER_TTY=(-i)
fi

log "Starting ISO build container ($PLATFORM, build volume: $BUILD_VOLUME)"
docker run --rm "${DOCKER_TTY[@]}" \
  --platform "$PLATFORM" \
  --privileged \
  -e MINT_ISO_URL \
  -e MINT_SHA256_URL \
  -e MINT_ISO_NAME \
  -e OUTPUT_ISO_NAME \
  -e ISO_VOLUME_ID \
  -v "$REPO_ROOT:/workspace:rw" \
  -v "$CACHE_DIR:/workspace/.cache/iso:rw" \
  -v "$DIST_DIR:/workspace/dist:rw" \
  -v "$BUILD_VOLUME:/workspace/.build/iso" \
  -w /workspace \
  "$IMAGE_NAME" \
  "$@"

log "Done. Artifacts:"
ls -lh "$DIST_DIR"/ArcanusOS-Alpha-x86_64.iso* 2>/dev/null || ls -lh "$DIST_DIR"
