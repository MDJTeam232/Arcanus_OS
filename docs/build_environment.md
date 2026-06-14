# Build Environment

## GitHub Actions

The primary build environment is `ubuntu-latest`.

The workflow installs:

- `ca-certificates`
- `curl`
- `gpg`
- `isolinux`
- `ripgrep`
- `rsync`
- `squashfs-tools`
- `syslinux-common`
- `xorriso`

## Local Linux Build

Use Ubuntu or Debian with at least:

- 8 GB RAM
- 25 GB free disk space
- Root/sudo access
- Reliable network connection for the upstream ISO download

Install dependencies:

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

## macOS

macOS is fine for editing and `make validate`, but not for the ISO build. The build needs Linux chroot, mount, SquashFS, initramfs, and ISO boot tooling.

## Workspace Paths

```text
.cache/iso/       downloaded upstream ISO and checksum
.build/iso/       extracted ISO and live filesystem
dist/             final Arcanus ISO and checksum
```
