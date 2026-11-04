# Raspberry Pi 5 target

This is the active firmware target in this repository.

## Hardware

- Raspberry Pi 5 or Raspberry Pi 500
- Morse Micro MM8108 USB module, including Gateworks MM8108 hardware
- Optional Pi 5 onboard Wi-Fi and USB Wi-Fi adapters

The kernel, device tree, Morse driver, and MM8108 firmware come from the Build with Parallel Pi 5 OpenWrt tree and its pinned Morse feed. No unrelated Pi driver changes are required for the MM8108 USB path.

## Image profile

The profile is `boards/ekh-bcm2712/target_diffconfig` and produces images in `bin/targets/bcm27xx/bcm2712/`. It selects:

- Raspberry Pi 5 (`rpi-5`) 6.6 kernel support
- Morse MM8108 USB driver and firmware
- `openmanetd` and Alfred
- Docker, Compose, containerd, and runc
- OpenTAKServer's OpenWrt deployment package

The image uses a 64 MB boot partition and a 4 GB SquashFS/rootfs partition. OpenTAKServer data and Docker layers live on the writable overlay.

## Build

From the repository root:

```sh
./scripts/openmanet_setup.sh -i -b ekh-bcm2712
make download -j4
make -j$(nproc) V=s
```

The setup script installs the pinned Morse and OpenMANET feeds and applies the host-build compatibility patches. Generated output is intentionally ignored by Git.

## First boot

Flash the factory image to an SD card, connect directly to Ethernet, and use `10.41.254.1` for LuCI or SSH. Set a root password immediately. `openmanetd` is included in the image; the OpenTAKServer service starts after Docker is ready and pulls its ARM64 application images unless an offline bundle is supplied.

System-level Raspberry Pi 5 boot and RF operation require physical Pi 5/MM8108 hardware. QEMU system emulation was not used as an acceptance criterion because the available QEMU release has no Raspberry Pi 5 machine model.
