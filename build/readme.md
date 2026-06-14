# Arcanus OS Alpha

Arcanus OS Alpha is an installable x86_64 operating system image built from Linux Mint XFCE as the upstream base.

The target artifact is:

```text
dist/
├── ArcanusOS-Alpha-x86_64.iso
└── ArcanusOS-Alpha-x86_64.iso.sha256
```

The user should download `ArcanusOS-Alpha-x86_64.iso`, flash it with Rufus, Balena Etcher, Ventoy, or `dd`, boot it, and see Arcanus branding from the boot menu through the desktop.

## Milestone

The Alpha milestone is deliberately narrow:

```text
Power on
-> ARCANUS boot splash
-> ARCANUS OS login
-> Branded XFCE desktop
-> Arcanus Welcome / Control Centre
```

If someone sits down in front of the Dell OptiPlex and asks what operating system it is, the answer should be:

```text
Arcanus OS
```

Linux Mint is the engine. Arcanus is the operating system experience.

## Base System

Default upstream ISO:

```text
Linux Mint 22.3 "Zena" XFCE 64-bit
```

The URL is configured in [build/config/mint-alpha.conf](build/config/mint-alpha.conf) and can be overridden with `MINT_ISO_URL` and `MINT_SHA256_URL`.

## Build

```bash
make build
```

or:

```bash
sudo build/build-iso.sh
```

The build process:

1. Downloads the upstream Mint XFCE ISO.
2. Verifies its SHA256 checksum.
3. Extracts the ISO and live filesystem.
4. Applies the Arcanus root filesystem overlay.
5. Activates the Arcanus Plymouth boot theme.
6. Rebrands LightDM, XFCE defaults, wallpaper, theme, welcome, and control centre.
7. Rewrites visible ISO boot menu strings.
8. Regenerates initramfs, squashfs, manifests, and md5sums.
9. Rebuilds a bootable hybrid ISO.
10. Writes the release SHA256 checksum.

## Validate

```bash
make validate
```

## Apply Overlay Manually

For debugging a mounted Mint root filesystem:

```bash
sudo scripts/apply-branding.sh /mnt/mint-rootfs
```

For a running Mint XFCE test install:

```bash
sudo scripts/apply-branding.sh /
```

The ISO builder uses the same branding layer.

## Project Layout

```text
branding/
├── boot/
├── login/
├── wallpapers/
├── icons/
├── logos/
└── rootfs/

theme/
└── arcanus-dark/

control-centre/

build/
├── build-iso.sh
├── build-locally.sh
├── config/
└── mint/

docs/
```

## Deferred

- Product applications
- Deeper platform integrations
- Full icon redesign

Mint icons stay in place for Alpha.
