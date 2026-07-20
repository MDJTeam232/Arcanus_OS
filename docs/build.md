# Build Guide - Arcanus OS Alpha

This repository builds installable Arcanus OS Alpha ISO media from Linux Mint XFCE.

## Output

```text
dist/ArcanusOS-Alpha-x86_64.iso
dist/ArcanusOS-Alpha-x86_64.iso.sha256
```

## Default Upstream

Configured in `build/config/mint-alpha.conf`:

```text
Linux Mint 22.3 "Zena" XFCE 64-bit
```

The upstream ISO URL and checksum URL can be overridden:

```bash
sudo MINT_ISO_URL=https://mirror/path/linuxmint-xfce.iso \
  MINT_SHA256_URL=https://mirror/path/sha256sum.txt \
  build/build-iso.sh
```

## Local Build

### Option A — Docker (recommended on macOS)

Requires Docker Desktop (or any Docker engine). The upstream Mint ISO is cached under `.cache/iso/` (~2.8 GB).

```bash
make build-docker
```

or:

```bash
build/build-docker.sh
```

### Option B — Native Linux

Ubuntu/Debian host dependencies:

```bash
sudo apt-get update
sudo apt-get install -y \
  ca-certificates curl gpg isolinux rsync squashfs-tools \
  syslinux-common xorriso ripgrep
```

Build:

```bash
make build
```

or:

```bash
sudo build/build-iso.sh
```

Root is required because the build extracts and regenerates a Linux root filesystem with correct ownership, chroots into it, and regenerates initramfs.

## Build Process

1. Download upstream Mint XFCE ISO.
2. Verify upstream SHA256.
3. Extract ISO contents with `xorriso`.
4. Extract `casper/filesystem.squashfs`.
5. Apply `rootfs`.
6. Install Arcanus wallpapers, logos, theme, Welcome, and Control Centre.
7. Activate the Arcanus Plymouth theme in the live filesystem.
8. Regenerate initramfs and copy it back into `casper/`.
9. Replace visible Mint strings in boot menus, desktop launchers, and installer metadata.
10. Regenerate filesystem manifests and squashfs.
11. Regenerate ISO md5sums.
12. Repack a bootable hybrid ISO.
13. Generate SHA256 for the final ISO.

## Manual Overlay Debugging

Apply branding to a mounted root filesystem:

```bash
sudo scripts/apply-branding.sh /mnt/mint-rootfs
```

Apply directly to a running Mint XFCE test machine:

```bash
sudo scripts/apply-branding.sh /
```

## Success Criteria

The ISO passes Alpha when the Dell boots into:

```text
ARCANUS
ARCANUS OS
Arcanus OS Alpha
```

with no visible Linux Mint branding in the normal boot, login, desktop, welcome, or about path.
