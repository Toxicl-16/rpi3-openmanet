# Raspberry Pi 5 OpenMANET firmware 0.5.9

This release is the v0.5.2-based Raspberry Pi 5 SquashFS build with the
targeted OpenMANET additions and an explicit BCM43455 firmware fix.

## Fix in this release

The Raspberry Pi 5 onboard Wi-Fi firmware package now provides the model
specific files requested by `brcmfmac`, including:

`brcmfmac43455-sdio.raspberrypi,5-model-b.bin`

The corresponding Pi 5 `clm_blob` and Compute Module/500 aliases are included
as well. The aliases point to the packaged Cypress BCM43455 firmware.

## Included

- Buildwithparallel Morse Micro firmware and drivers.
- OpenMANET wizard and portal.
- BATMAN-V `bat0` integration.
- `openmanetd` and OpenTAKServer packages.
- First-boot SD-card expansion for the writable overlay.
- Docker/F2FS capability support.
- SquashFS factory and sysupgrade images only.

PiAware, dump1090, and ext4 release images are not included.

## Validation

- Pi 5 source checks: passed.
- Full firmware rebuild: passed.
- SquashFS inspection: passed; Pi 5 BCM43455 `.bin`, `.clm_blob`, and `.txt`
  paths are present.
- Morse MM8108 firmware is present.
- No physical Raspberry Pi 5 hardware test was performed on the build host.
- QEMU cannot fully boot this target because the available QEMU version has no
  Raspberry Pi 5 machine model; it cannot validate SDIO, Ethernet, MM8108, AP,
  Docker, or mesh operation.

## Installation

For a new SD card, flash the factory image. For an existing compatible OpenWrt
installation, use the sysupgrade image. After boot, connect directly to the Pi
Ethernet port at `10.41.254.1`, set the root password, and complete the
OpenMANET/Morse wizard.

## Checksums

Factory image:

`98f6edddd0a41fa55a950737813ac309e0b2985d3d92883a8999c7fb7ae5c39a`

Sysupgrade image:

`d57a845e1e8313c2c15eaa4a6106450d5011ebf11e09039d3c1a32b49f0ec47e`
