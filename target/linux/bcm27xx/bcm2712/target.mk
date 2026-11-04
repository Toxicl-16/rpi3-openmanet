# SPDX-License-Identifier: GPL-2.0-only

ARCH:=aarch64
# The Pi 5 compiler target is Cortex-A76, but OpenWrt does not publish a
# release feed for aarch64_cortex-a76. The generic Cortex-A72 userspace ABI
# is compatible with the Pi 5 and is the supported 23.05 package feed.
ARCH_PACKAGES:=aarch64_cortex-a72
SUBTARGET:=bcm2712
BOARDNAME:=BCM2712 boards (64 bit)
CPU_TYPE:=cortex-a76
FEATURES+=pci pcie

define Target/Description
	Build firmware image for BCM2712 devices.
	This firmware features a 64 bit kernel.
endef
