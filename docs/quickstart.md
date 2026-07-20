# Quick Reference - Arcanus OS Alpha

## Build Output

```text
dist/
├── ArcanusOS-Alpha-x86_64.iso
└── ArcanusOS-Alpha-x86_64.iso.sha256
```

## Commands

```bash
make validate
make build          # native Linux + sudo
make build-docker   # macOS or Linux via Docker
```

Equivalent direct build:

```bash
sudo build/build-iso.sh
# or on macOS:
build/build-docker.sh
```

## Flashing

Use one of:

- Rufus
- Balena Etcher
- Ventoy
- `dd`

Linux example:

```bash
sudo dd if=dist/ArcanusOS-Alpha-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## GitHub Actions

Push to `main`:

```text
Validate
-> Build ISO
-> Generate checksum
-> Upload workflow artifact
-> Create prerelease
```

## Manual Overlay Debugging

```bash
sudo scripts/apply-branding.sh /mnt/mint-rootfs
sudo scripts/apply-branding.sh /
```

## Dell Test

Boot the USB and confirm:

- Boot menu says Arcanus OS
- Boot splash says `ARCANUS`
- Login screen reads as `ARCANUS OS`
- Desktop wallpaper is the Arcanus mountain wallpaper
- Welcome opens as Arcanus Welcome
- About surfaces say `Arcanus OS Alpha`
