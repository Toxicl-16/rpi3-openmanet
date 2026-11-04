# Raspberry Pi 5 target

This is the active firmware target in this repository.

## Hardware

- Raspberry Pi 5 or Raspberry Pi 500
- Morse Micro MM8108 USB module, including Gateworks MM8108 hardware
- Pi 5 onboard Wi-Fi (included); other Wi-Fi adapters are optional and not part
  of the vanilla profile

The kernel, device tree, Morse driver, and MM8108 firmware come from the Build with Parallel Pi 5 OpenWrt tree and its pinned Morse feed. No unrelated Pi driver changes are required for the MM8108 USB path.

## Image profile

The profile is `boards/ekh-bcm2712/target_diffconfig` and produces images in `bin/targets/bcm27xx/bcm2712/`. It selects:

- Raspberry Pi 5 (`rpi-5`) 6.6 kernel support
- Morse MM8108 USB driver and firmware
- `openmanetd` and its declared Alfred/runtime dependencies
- OpenMANET Argon LuCI configuration theme
- The upstream OpenMANET `802.11s Mesh` wizard, including Mesh Gate setup
- Docker, Compose, containerd, and runc
- OpenTAKServer's OpenWrt deployment package

The profile deliberately does not select Build with Parallel's optional
PiAware/ADS-B, VPN, LoRa/Reticulum, diagnostics, or sidecar-driver bundles.

The image uses a 64 MB boot partition and a 4 GB SquashFS/rootfs partition. OpenTAKServer data and Docker layers live on the writable overlay. The image does not include PiAware, dump1090, or the unrelated ADS-B web service; port 8080 is not reserved by this build.

## Build

From the repository root:

```sh
./scripts/openmanet_setup.sh -i -b ekh-bcm2712
make download -j4
make -j$(nproc) V=s
```

The setup script installs the pinned Morse and OpenMANET feeds and applies the host-build compatibility patches. Generated output is intentionally ignored by Git.

## First boot

Flash the factory image to an SD card, connect directly to Ethernet, and use
`10.41.254.1` for LuCI or SSH. Set a root password immediately. Open LuCI's
**Wizards** menu, choose **802.11s Mesh**, and select **Mesh Gate** when this
Pi is the Internet gateway. `openmanetd` is included in the image; the
OpenTAKServer service starts after Docker is ready and pulls its ARM64
application images unless an offline bundle is supplied.

See the [startup checklist](startup.md) for the full gate/point setup,
verification commands, MM8108 path workaround, and OpenTAKServer instructions.

OpenTAKServer provides its web UI at `http://NODE_IP:8090`, API at
`http://NODE_IP:8091`, plain TCP CoT at `NODE_IP:8088`, and TLS CoT at
`NODE_IP:8089`. Use the TLS CoT endpoint for ATAK after the server's
certificates/users are configured in the web UI.

System-level Raspberry Pi 5 boot and RF operation require physical Pi 5/MM8108 hardware. QEMU system emulation was not used as an acceptance criterion because the available QEMU release has no Raspberry Pi 5 machine model.
