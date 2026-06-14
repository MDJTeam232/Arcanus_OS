# Mint Upstream Track

Arcanus OS Alpha currently uses Linux Mint XFCE as the upstream x86_64 base.

The build script downloads the configured Mint ISO, applies Arcanus branding, and emits:

```text
dist/ArcanusOS-Alpha-x86_64.iso
```

This directory is reserved for future Mint-specific build helpers if the ISO process needs to grow beyond `build/build-iso.sh`.
