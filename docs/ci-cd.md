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
  -> install ISO build dependencies
  -> sudo build/build-iso.sh
  -> sha256sum -c
  -> upload workflow artifact
  -> create GitHub prerelease on main
```

## Release Artifacts

```text
ArcanusOS-Alpha-x86_64.iso
ArcanusOS-Alpha-x86_64.iso.sha256
```

Release tags use:

```text
alpha-<run-number>
```

## Pull Requests

Pull requests run validation only. ISO builds and releases run on direct pushes to `main` or manual workflow dispatch.
