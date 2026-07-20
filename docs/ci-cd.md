# CI/CD

GitHub Actions builds Arcanus OS Alpha installation media.

Workflow:

```text
.github/workflows/build-image.yml
```

## Jobs

```text
validate
  -> make validate

build-iso
  -> free runner disk space
  -> restore cached Mint ISO (when available)
  -> install ISO build dependencies
  -> sudo build/build-iso.sh
  -> sha256sum -c
  -> upload workflow artifact (14-day retention)
  -> create GitHub prerelease on main
```

## How to get the ISO

### Workflow artifact (every main push / manual run)

1. Open the repo on GitHub → **Actions**
2. Select **Build Arcanus OS Alpha ISO**
3. Open the latest successful run
4. Download **ArcanusOS-Alpha-x86_64** under **Artifacts**

Artifacts keep both:

```text
ArcanusOS-Alpha-x86_64.iso
ArcanusOS-Alpha-x86_64.iso.sha256
```

Retention: **14 days**.

### Manual run

**Actions** → **Build Arcanus OS Alpha ISO** → **Run workflow**

Uses `workflow_dispatch` so you can build without a code change.

### GitHub prerelease (main only)

On push to `main`, the workflow also creates a prerelease tag:

```text
alpha-<run-number>
```

**GitHub Release assets are limited to 2 GiB per file.** The full ISO is larger (~2.7–2.9 GiB), so Releases attach:

```text
ArcanusOS-Alpha-x86_64.iso.part00
ArcanusOS-Alpha-x86_64.iso.part01
…
ArcanusOS-Alpha-x86_64.iso.sha256
```

Reassemble and verify:

```bash
cat ArcanusOS-Alpha-x86_64.iso.part* > ArcanusOS-Alpha-x86_64.iso
sha256sum -c ArcanusOS-Alpha-x86_64.iso.sha256
```

Prefer the **workflow artifact** when it is still within the 14-day retention window (single full ISO download).

### Storage limits (why old artifacts matter)

| Limit | What it affects |
|-------|-----------------|
| **Actions artifact storage** (account/org quota) | Upload of workflow artifacts fails when quota is full. Delete old artifacts or shorten `retention-days`. |
| **Release asset size (2 GiB/file)** | Cannot attach the full ISO to a Release; we split or use Artifacts. |
| **Release storage** | Old prereleases with multi‑GB assets still count; delete unused `alpha-*` releases if needed. |

Cleaning expired or unused Artifacts/Releases is expected hygiene for this project.

## Pull Requests

Pull requests run **validation only**. ISO builds and releases run on:

- direct pushes to `main` (when relevant paths change)
- manual **workflow_dispatch**
