# Arcanus OS Alpha - Build Makefile

.PHONY: help validate build apply package clean

ROOTFS ?= /mnt/mint-rootfs

help:
	@echo "Arcanus OS Alpha"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  validate          - Check branding scaffold"
	@echo "  build             - Build dist/ArcanusOS-Alpha-x86_64.iso"
	@echo "  apply ROOTFS=...  - Apply branding to a mounted Mint rootfs"
	@echo "  package IMAGE=... - Copy/rename an image artifact into dist/"
	@echo "  clean             - Clean generated artifacts"

validate:
	@scripts/verify-setup.sh

build: validate
	@build/build-locally.sh

apply:
	@scripts/apply-branding.sh "$(ROOTFS)"

package:
	@[ -n "$(IMAGE)" ] || { echo "Usage: make package IMAGE=/path/to/image.img.xz"; exit 2; }
	@scripts/package-artifact.sh "$(IMAGE)"

clean:
	@rm -rf .build/iso dist/*.img dist/*.img.xz dist/*.iso dist/*.sha256
	@echo "Clean complete"

.DEFAULT_GOAL := help
