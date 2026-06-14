# Build Artifacts

Successful ISO builds write:

```text
dist/
├── ArcanusOS-Alpha-x86_64.iso
└── ArcanusOS-Alpha-x86_64.iso.sha256
```

Flash the ISO with Rufus, Balena Etcher, Ventoy, or `dd`.

The ISO builder keeps downloaded upstream media under `.cache/iso/` and temporary extraction state under `.build/iso/`.
