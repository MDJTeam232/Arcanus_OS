#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# build-iso.sh — Create an ISO image from a source directory
#
# Features:
# - Strict mode with cleanup on exit
# - Cross-platform tool detection (xorriso/genisoimage/mkisofs/hdiutil)
# - Reproducibility hooks via SOURCE_DATE_EPOCH
# - Clear CLI with verbose and dry-run options
# - Optional checksum emission
#
# Usage:
#   ./build-iso.sh -s <source_dir> -o <output.iso> [-l <label>] [--force] [-v] [-n]
#
# Example:
#   ./build-iso.sh -s dist -o MyProduct.iso -l MY_PRODUCT -v --force

SCRIPT_NAME="${0##*/}"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-1700000000}"
LABEL="Arcanus"
SRC_DIR=""
OUT_ISO="output.iso"
VERBOSE=0
DRY_RUN=0
FORCE=0
EFI_IMG=""
BIOS_BOOT_IMG=""
BOOT_CATALOG="boot.cat"
EFI_DIR=""
EFI_SIZE_MB=""
STAGED_SRC=""
EFI_BOOT_PATH=""
BIOS_BOOT_PATH=""

PUBLISHER="Arcanus"
PREPARER="Arcanus"
APPID="Arcanus"
SYSID="Arcanus"

log()  { printf '[%s] %s\n' "$SCRIPT_NAME" "$*" >&2; }
vlog() { if [[ "$VERBOSE" -eq 1 ]]; then log "$@"; fi; }
die()  { log "ERROR: $*"; exit 1; }

usage() {
  cat >&2 <<EOF
Usage: $SCRIPT_NAME -s <source_dir> -o <output.iso> [-l <label>] [--force] [-v] [-n]
Options:
  -s, --source DIR     Directory to package into the ISO (required)
  -o, --output FILE    Output ISO path (default: $OUT_ISO)
  -l, --label NAME     Volume label (default: $LABEL)
  -v, --verbose        Verbose logging
  -n, --dry-run        Show actions but do not execute
  --efi-img FILE       Path to an EFI System Partition image to use for EFI boot (El Torito)
  --bios-boot FILE     Path to BIOS/ISOLINUX boot image for legacy boot (El Torito)
  --boot-catalog FILE  Path/name of El Torito boot catalog (default: boot.cat)
  --efi-dir DIR        Directory whose contents will be packaged into an EFI System Partition image
  --efi-size-mb N      Size in megabytes for generated EFI image (auto-calculated if omitted)
      --force          Overwrite output if it exists
  -h, --help           Show this help
Environment:
  SOURCE_DATE_EPOCH    Unix timestamp used to normalize file/volume dates
EOF
}

cleanup() {
  local ec=$?
  if [[ -n "${TMPDIR_ISO:-}" && -d "${TMPDIR_ISO:-}" ]]; then
    rm -rf -- "$TMPDIR_ISO" || true
  fi
  exit "$ec"
}
trap cleanup EXIT INT TERM

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required tool: $1"
}

# Parse args
if [[ $# -eq 0 ]]; then usage; exit 1; fi
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--source) SRC_DIR="${2:-}"; shift 2 ;;
    -o|--output) OUT_ISO="${2:-}"; shift 2 ;;
    -l|--label)  LABEL="${2:-}"; shift 2 ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -n|--dry-run) DRY_RUN=1; shift ;;
    --force)      FORCE=1; shift ;;
    --efi-img) EFI_IMG="${2:-}"; shift 2 ;;
    --bios-boot) BIOS_BOOT_IMG="${2:-}"; shift 2 ;;
    --boot-catalog) BOOT_CATALOG="${2:-}"; shift 2 ;;
    --efi-dir) EFI_DIR="${2:-}"; shift 2 ;;
    --efi-size-mb) EFI_SIZE_MB="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$SRC_DIR" ]] || { usage; die "Missing --source"; }
[[ -d "$SRC_DIR" ]] || die "Source directory does not exist: $SRC_DIR"
if [[ -n "$EFI_IMG" && ! -f "$EFI_IMG" ]]; then die "EFI image not found: $EFI_IMG"; fi
if [[ -n "$BIOS_BOOT_IMG" && ! -f "$BIOS_BOOT_IMG" ]]; then die "BIOS boot image not found: $BIOS_BOOT_IMG"; fi
if [[ -z "$EFI_IMG" && -n "$EFI_DIR" && ! -d "$EFI_DIR" ]]; then die "EFI directory not found: $EFI_DIR"; fi

# Resolve output path and handle overwrite
if [[ -e "$OUT_ISO" && "$FORCE" -ne 1 ]]; then
  die "Output exists: $OUT_ISO (use --force to overwrite)"
fi
if [[ "$FORCE" -eq 1 && -e "$OUT_ISO" ]]; then
  vlog "Removing existing $OUT_ISO"
  if [[ "$DRY_RUN" -eq 0 ]]; then rm -f -- "$OUT_ISO"; fi
fi

# Create staging dir (available for future transforms if needed)
TMPDIR_ISO="$(mktemp -d -t iso.XXXXXXXX)" || die "Failed to create temp dir"
vlog "Staging at: $TMPDIR_ISO"

stage_source_tree() {
  STAGED_SRC="$TMPDIR_ISO/source"
  mkdir -p "$STAGED_SRC"
  cp -R "$SRC_DIR"/. "$STAGED_SRC"/
}

stage_boot_image() {
  local source="$1"
  local relative_target="$2"
  local target="$STAGED_SRC/$relative_target"

  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
  printf '%s\n' "$relative_target"
}

# Tool detection
OS="$(uname -s)"
HAVE_XORRISO=0; HAVE_GENISO=0; HAVE_HDIUTIL=0
command -v xorriso >/dev/null 2>&1 && HAVE_XORRISO=1
command -v genisoimage >/dev/null 2>&1 && HAVE_GENISO=1
command -v mkisofs >/dev/null 2>&1 && HAVE_GENISO=1
if [[ "$OS" == "Darwin" ]]; then
  command -v hdiutil >/dev/null 2>&1 && HAVE_HDIUTIL=1
fi

generate_efi_image() {
  log "Generating EFI System Partition image from: $EFI_DIR"
  require_cmd dd
  local size_mb
  if [[ -n "$EFI_SIZE_MB" ]]; then
    size_mb="$EFI_SIZE_MB"
  else
    local size_kb overhead_kb total_kb
    size_kb=$(du -sk "$EFI_DIR" | awk '{print $1}')
    overhead_kb=2048
    total_kb=$((size_kb + overhead_kb))
    size_mb=$(( (total_kb + 1023) / 1024 ))
    if [[ "$size_mb" -lt 10 ]]; then size_mb=10; fi
  fi
  local img="$TMPDIR_ISO/efiboot.img"
  log "Creating EFI image $img (${size_mb}MB)"
  dd if=/dev/zero of="$img" bs=1M count="$size_mb" status=none

  if command -v mkfs.vfat >/dev/null 2>&1 && command -v mcopy >/dev/null 2>&1 && command -v mmd >/dev/null 2>&1; then
    # Linux/Unix path using dosfstools + mtools (preferred)
    mkfs.vfat -F32 -n EFI "$img" >/dev/null
    mmd -i "$img" ::/EFI || true
    mmd -i "$img" ::/EFI/BOOT || true
    if compgen -G "$EFI_DIR/*" >/dev/null 2>&1; then
      mcopy -s -i "$img" "$EFI_DIR"/* ::/ >/dev/null
    fi
  elif [[ "$OS" == "Darwin" ]] && command -v newfs_msdos >/dev/null 2>&1 && command -v hdiutil >/dev/null 2>&1; then
    # macOS fallback using newfs_msdos + hdiutil attach/cp/detach
    # Attach the raw image without mounting to get a device node
    local dev
    dev=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nomount "$img" | awk '/^\/dev\// {print $1; exit}')
    if [[ -z "$dev" ]]; then
      die "Failed to attach EFI image (nomount) on macOS"
    fi
    # Create a FAT32 filesystem on the raw device
    newfs_msdos -F 32 -v EFI "$dev" >/dev/null
    # Detach the raw device, then re-attach with a mountpoint to copy files
    hdiutil detach "$dev" >/dev/null || true
    local mnt="$TMPDIR_ISO/efimnt"
    mkdir -p "$mnt"
    dev=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage -nobrowse -readwrite -noverify -mountpoint "$mnt" "$img" | awk '/^\/dev\// {print $1; exit}')
    if [[ -z "$dev" ]]; then
      die "Failed to attach/mount EFI image on macOS"
    fi
    if compgen -G "$EFI_DIR/*" >/dev/null 2>&1; then
      cp -R "$EFI_DIR"/. "$mnt"/
    fi
    sync
    hdiutil detach "$dev" >/dev/null
  else
    die "Missing tools to create EFI image. Install mtools+dosfstools (mkfs.vfat,mcopy,mmd) or on macOS use newfs_msdos+hdiutil."
  fi

  EFI_IMG="$img"
  log "Generated EFI image at: $EFI_IMG"
}

# Auto-generate EFI image if a directory is provided and no image is set
if [[ -z "$EFI_IMG" && -n "$EFI_DIR" ]]; then
  generate_efi_image
fi

stage_source_tree

if [[ -n "$BIOS_BOOT_IMG" ]]; then
  BIOS_BOOT_PATH="$(stage_boot_image "$BIOS_BOOT_IMG" ".iso-boot/$(basename "$BIOS_BOOT_IMG")")"
  vlog "Staged BIOS boot image at: $BIOS_BOOT_PATH"
fi

if [[ -n "$EFI_IMG" ]]; then
  EFI_BOOT_PATH="$(stage_boot_image "$EFI_IMG" ".iso-boot/efiboot.img")"
  vlog "Staged EFI boot image at: $EFI_BOOT_PATH"
fi

build_with_xorriso() {
  # Use mkisofs compatibility mode for portability
  local cmd=(xorriso -as mkisofs
    -iso-level 3
    -J -R
    -V "$LABEL"
    -publisher "$PUBLISHER" -preparer "$PREPARER" -A "$APPID" -sysid "$SYSID"
    -output "$OUT_ISO"
  )
  # Add BIOS El Torito boot entry if provided
  if [[ -n "$BIOS_BOOT_PATH" ]]; then
    cmd+=( -b "$BIOS_BOOT_PATH" -c "$BOOT_CATALOG" -no-emul-boot -boot-load-size 4 -boot-info-table )
  fi
  # Add EFI El Torito boot entry if provided
  if [[ -n "$EFI_BOOT_PATH" ]]; then
    if [[ -n "$BIOS_BOOT_PATH" ]]; then
      cmd+=( -eltorito-alt-boot )
    else
      cmd+=( -eltorito-catalog "$BOOT_CATALOG" )
    fi
    cmd+=( -eltorito-platform efi -eltorito-boot "$EFI_BOOT_PATH" -no-emul-boot )
  fi
  # Append source directory last
  cmd+=( "$STAGED_SRC" )
  printf '%s\n' "${cmd[*]}"
  if [[ "$DRY_RUN" -eq 0 ]]; then "${cmd[@]}"; fi
}

build_with_geniso() {
  local mk="genisoimage"
  command -v mkisofs >/dev/null 2>&1 && mk="mkisofs"
  local cmd=("$mk"
    -iso-level 3
    -J -R
    -V "$LABEL"
    -publisher "$PUBLISHER" -preparer "$PREPARER" -A "$APPID" -sysid "$SYSID"
  )
  # Add BIOS El Torito boot entry if provided
  if [[ -n "$BIOS_BOOT_PATH" ]]; then
    cmd+=( -b "$BIOS_BOOT_PATH" -c "$BOOT_CATALOG" -no-emul-boot -boot-load-size 4 -boot-info-table )
  fi
  # Add EFI El Torito boot entry if provided
  if [[ -n "$EFI_BOOT_PATH" ]]; then
    if [[ -n "$BIOS_BOOT_PATH" ]]; then
      cmd+=( -eltorito-alt-boot )
    fi
    # genisoimage/mkisofs typically uses -e for EFI boot image
    cmd+=( -e "$EFI_BOOT_PATH" -no-emul-boot )
  fi
  # Output and source
  cmd+=( -o "$OUT_ISO" "$STAGED_SRC" )
  printf '%s\n' "${cmd[*]}"
  if [[ "$DRY_RUN" -eq 0 ]]; then "${cmd[@]}"; fi
}

build_with_hdiutil() {
  # macOS hybrid ISO (ISO9660 + Joliet); add -udf if needed
  if [[ -n "$BIOS_BOOT_IMG" && -n "$EFI_IMG" ]]; then
    die "hdiutil cannot include multiple El Torito entries; install xorriso or genisoimage/mkisofs for BIOS+EFI."
  fi
  local cmd=(hdiutil makehybrid
    -iso -joliet
    -default-volume-name "$LABEL"
  )
  if [[ -n "$BIOS_BOOT_PATH" ]]; then
    cmd+=( -eltorito-boot "$BIOS_BOOT_PATH" -no-emul-boot -eltorito-catalog "$BOOT_CATALOG" )
  fi
  if [[ -n "$EFI_BOOT_PATH" ]]; then
    cmd+=( -eltorito-boot "$EFI_BOOT_PATH" -no-emul-boot -eltorito-catalog "$BOOT_CATALOG" )
  fi
  cmd+=( -o "$OUT_ISO" "$STAGED_SRC" )
  printf '%s\n' "${cmd[*]}"
  if [[ "$DRY_RUN" -eq 0 ]]; then "${cmd[@]}"; fi
}

log "Building ISO"
log "Label: $LABEL"
log "Source: $SRC_DIR"
log "Output: $OUT_ISO"
log "SOURCE_DATE_EPOCH: $SOURCE_DATE_EPOCH"
if [[ -n "$BIOS_BOOT_IMG" ]]; then log "BIOS El Torito boot image: $BIOS_BOOT_IMG"; fi
if [[ -n "$EFI_IMG" ]]; then log "EFI El Torito boot image: $EFI_IMG"; fi
log "Branding: publisher=$PUBLISHER, preparer=$PREPARER, appid=$APPID, sysid=$SYSID"

if [[ "$HAVE_XORRISO" -eq 1 ]]; then
  vlog "Using xorriso"
  build_with_xorriso
elif [[ "$HAVE_GENISO" -eq 1 ]]; then
  vlog "Using genisoimage/mkisofs"
  build_with_geniso
elif [[ "$HAVE_HDIUTIL" -eq 1 ]]; then
  vlog "Using hdiutil (macOS)"
  build_with_hdiutil
else
  die "No ISO creation tool found (xorriso, genisoimage/mkisofs, or hdiutil)."
fi

# Optional: emit checksum
if [[ "$DRY_RUN" -eq 0 && -f "$OUT_ISO" ]]; then
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$OUT_ISO" > "${OUT_ISO}.sha256"
    vlog "Wrote checksum: ${OUT_ISO}.sha256"
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$OUT_ISO" > "${OUT_ISO}.sha256"
    vlog "Wrote checksum: ${OUT_ISO}.sha256"
  fi
fi

log "Done."
