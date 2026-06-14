# UEFI Boot Configuration Template
#
# Legacy scaffold note: the active Arcanus OS Alpha build remasters Linux Mint
# with build/build-iso.sh and does not use this directory.
#
# This directory will be packaged into an EFI System Partition image.
# The build-iso.sh script expects:
# - BOOTX64.EFI (x86_64 UEFI bootloader)
# - BOOTAA64.EFI (ARM64 UEFI bootloader, optional)
#
# Obtain bootloaders from:
# 1. Your bootloader project (GRUB, systemd-boot, etc.)
# 2. Linux Mint ISO EFI partition
# 3. systemd-boot or other UEFI reference implementations

# To use existing Linux Mint EFI bootloaders:
# 1. Mount the upstream Mint ISO
# 2. Extract: EFI/BOOT/BOOTX64.EFI from the ISO
# 3. Place it here: BOOTX64.EFI
