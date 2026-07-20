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

with the same ISO + SHA256 attached under **Releases**.

## Pull Requests

Pull requests run **validation only**. ISO builds and releases run on:

- direct pushes to `main` (when relevant paths change)
- manual **workflow_dispatch**
