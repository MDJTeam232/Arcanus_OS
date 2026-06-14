# Arcanus OS Alpha Setup Summary

The repository now builds Arcanus OS Alpha installation media.

## Output

```text
dist/
├── ArcanusOS-Alpha-x86_64.iso
└── ArcanusOS-Alpha-x86_64.iso.sha256
```

## Active Build Path

```text
GitHub / Ubuntu runner
-> Download Linux Mint XFCE upstream ISO
-> Verify upstream checksum
-> Extract ISO
-> Extract live squashfs
-> Apply Arcanus branding
-> Activate Plymouth
-> Regenerate initramfs
-> Regenerate squashfs
-> Rebuild bootable ISO
-> Generate SHA256
-> Upload release artifacts
```

## Main Commands

```bash
make validate
make build
sudo build/build-iso.sh
```

## Installed Surfaces

- ISO boot menu text
- Plymouth boot splash
- Login wallpaper and greeter configuration
- Desktop wallpaper defaults
- System identity files
- Arcanus Dark theme scaffold
- First-login Welcome
- Arcanus Control Centre

## Deferred

All product applications and deeper platform integrations remain deferred until the OS identity passes on the Dell.
