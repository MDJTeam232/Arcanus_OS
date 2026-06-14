# Alpha Build Phases

## Phase 1 - Arcanus ISO Pipeline

Target:

```text
dist/ArcanusOS-Alpha-x86_64.iso
```

Deliverables:

- Download and verify Mint XFCE upstream ISO
- Apply Arcanus rootfs overlay
- Activate Plymouth boot branding
- Rebrand ISO boot menu strings
- Regenerate squashfs and ISO checksums
- Repack bootable x86_64 ISO
- Upload release artifact from GitHub Actions

Success criteria:

- The Dell boots from USB and shows Arcanus OS branding from boot through desktop.

## Phase 2 - Visual Polish

Deliverables:

- Improve boot menu background if needed
- Refine Plymouth animation
- Tighten LightDM layout
- Expand Arcanus Dark theme coverage

Success criteria:

- A non-technical user identifies the machine as Arcanus OS without prompting.

## Phase 3 - Control Centre

Deliverables:

- Replace shell/Zenity stub with a native lightweight app
- System, Security, Workspace, and About sections
- Clean launcher and settings integration

Success criteria:

- Arcanus has one unique first-party system application.

## Later

Deferred until the OS identity works:

- Product applications
- Deeper platform integrations
- Custom icon set
