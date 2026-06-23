# Arcanus OS Alpha - Build Makefile

.PHONY: help validate build apply package clean

# Default staging configuration targets
ROOTFS  ?= /mnt/mint-rootfs
PROFILE ?= --desktop

help:
	@echo "========================================================="
	@echo " Arcanus OS Alpha Build Engine"
	@echo "========================================================="
	@echo ""
	@echo "Usage: make [target] [PROFILE=--desktop|--tablet]"
	@echo ""
	@echo "Targets:"
	@echo "  validate          - Evaluate the selected structural workspace blueprint"
	@echo "  build             - Compile the production x86_64 installation ISO media"
	@echo "  apply ROOTFS=...  - Apply branding layouts directly onto a mounted rootfs target"
	@echo "  package IMAGE=... - Format, calculate checksums, and stage custom images in dist/"
	@echo "  clean             - Safely clear out scratch areas, build dirs, and local images"
	@echo ""
	@echo "Current Environment Profiles:"
	@echo "  Target Profile:   $(PROFILE)"
	@echo "  Mount Destination: $(ROOTFS)"

validate:
	@scripts/verify-setup.sh $(PROFILE)

build: validate
	@build/build-locally.sh $(PROFILE)

apply:
	@scripts/apply-branding.sh $(PROFILE) "$(ROOTFS)"

package:
	@[ -n "$(IMAGE)" ] || { echo "ERROR: Usage: make package IMAGE=/path/to/image.tar.gz"; exit 2; }
	@scripts/package-artifact.sh "$(IMAGE)"

clean:
	@rm -rf .build/iso .cache/iso dist/*.img dist/*.tar.gz dist/*.iso dist/*.sha256
	@echo "[arcanus-make] Clean complete. Staging buffers purged."

.DEFAULT_GOAL := help
