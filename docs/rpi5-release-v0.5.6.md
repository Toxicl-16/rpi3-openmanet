# Raspberry Pi 5 OpenMANET firmware 0.5.6

This release returns the Pi 5 image to the v0.5.2 boot and first-boot network
baseline, while retaining the source-level fixes needed for OpenMANETD,
OpenTAKServer, BATMAN-V, Docker, and full-card writable storage.

## Changes

- Restored the v0.5.2 kernel command line:
  `rootfstype=squashfs,ext4 rootwait`.
- Restored `CONFIG_TARGET_DEFAULT_LAN_IP_FROM_PREINIT=y`, matching the known
  bootable v0.5.2 Pi 5 profile and its `eth0`/`10.41.254.1` first-boot LAN.
- Kept the image SquashFS-only. No ext4 factory or sysupgrade image is built or
  released.
- Reworked the storage expansion hook to discover the SquashFS overlay offset
  at boot, expand the partition to the end of the SD card, and handle both
  ext4 and F2FS overlays offline. Fresh images are left to normal OpenWrt
  `fstools` filesystem selection after the partition is expanded.
- Added the ext4 repair/resize tools required by the compatibility path.
- Made the BATMAN-V repair wait for an explicit OpenMANET Mesh Gate/Point role
  from the wizard. A fresh node is no longer over-configured before the wizard
  has selected its role.
- Kept the Build with Parallel Morse MM8108 package and its shipped firmware
  file `mm8108b2-rl.bin`. The source tree contains no `mm8100 rpi5.bin` file;
  the expected MM8108 USB firmware is present in the image.
- Kept the Raspberry Pi 5 BCM43455 firmware, NVRAM link, and brcmfmac vendor
  modules in the image.
- Made the health report accept either supported writable overlay filesystem.

The image still contains OpenMANETD, the OpenMANET LuCI portal/wizard,
OpenTAKServer, Docker, BATMAN-adv, and the Morse Micro Pi 5 radio packages.
PiAware, dump1090, and the unrelated port-8080 application are not selected.

## Validation on the build host

- `scripts/tests/test-rpi5-source.sh` — pass.
- Shell syntax checks for the storage, BATMAN, and health scripts — pass.
- Full `make -j16 V=sc` image build — pass.
- Factory image inspection — pass: 64 MiB boot partition and 4 GiB initial
  Linux partition, with the preinit hook responsible for extending it on the
  first boot.
- Boot file inspection — pass: v0.5.2-compatible command line with
  `rootfstype=squashfs,ext4`.
- Root filesystem inspection — pass: OpenMANETD, OpenTAKServer, Docker,
  BATMAN, storage expansion, MM8108, BCM43455, and brcmfmac files are present.
- Kernel configuration inspection — pass: cgroups, memory cgroups, F2FS,
  F2FS xattrs/security, ext4/security, and kernel security are enabled.
- Release directory inspection — pass: only SquashFS factory/sysupgrade
  images are produced; no ext4 image is present.
- `git diff --check` — pass.

The build host cannot verify physical Pi 5 boot, Ethernet link negotiation,
MM8108 USB enumeration, SD-card growth on real media, Broadcom radio attach,
Docker capability xattrs, RF association, or multi-node mesh traffic. Those
remain required hardware checks on the supported Pi 5/MM8108 node. Boot
emulation is intentionally not used as an acceptance criterion.

## Installation

Use the SquashFS factory image for a fresh SD-card flash. The initial image
partition is 4 GiB so the factory artifact remains manageable; the first-boot
preinit hook expands the Linux partition to the end of the card and preserves
OpenWrt's normal overlay filesystem selection. Connect directly to Ethernet
after boot and use `10.41.254.1` to set the root password and run the
OpenMANET wizard. Select Mesh Gate or Mesh Point before expecting the BATMAN-V
topology repair to create `bat0`.

The generated `sha256sums` file in the release contains the authoritative
checksums for the two SquashFS images.
