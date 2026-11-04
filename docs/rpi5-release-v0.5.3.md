# Raspberry Pi 5 OpenMANET firmware 0.5.3

This release is the Build with Parallel Raspberry Pi 5 Morse firmware with the
OpenMANET daemon, OpenMANET LuCI portal, OpenTAKServer deployment, and the
source-level fixes recorded in `docs/rpi5_firmware_fixes.md`.

## Implemented and source/build verified

- The active image remains the `bcm2712` Pi 5 target with the Build with
  Parallel Morse MM8108 USB driver and firmware. Optional Build with Parallel
  bundles, including PiAware/dump1090, are not selected.
- The Pi 5 userspace package architecture is `aarch64_cortex-a72`, matching the
  available OpenWrt 23.05 package repositories. The unavailable bcm2712/a76
  target feed is omitted from generated `distfeeds.conf`.
- The root image is SquashFS with a writable F2FS `rootfs_data` overlay. The
  preinit hook discovers the SquashFS payload offset from the filesystem,
  expands the second partition to the end of the card, runs offline F2FS
  check/resize, and records an idempotence marker. It does not resize a mounted
  overlay or overwrite existing user data.
- Kernel memory/cgroup support is enabled and the Pi 5 device tree no longer
  disables memory cgroups. F2FS security xattrs and file capabilities are
  selected for Docker's `security.capability` metadata.
- Docker is explicitly configured for the `vfs` storage driver on the F2FS
  overlay. This preserves the existing `/opt/docker` layout and avoids an
  unverified storage migration during upgrade.
- `openmanet-node-fixes` repairs the OpenMANET BATMAN-V baseline without
  replacing the wizard's credentials or network design. It configures the
  documented multicast, bridge-loop, hop-penalty, interval, and distributed-ARP
  settings; binds mesh interfaces through `batadv_hardif`; disables 802.11s
  forwarding; and puts `bat0` in `br-ahwlan`. An explicitly disabled `bat0` is
  preserved until a mesh-gate role is selected.
- The OpenMANET home portal's light-only cards and graph surfaces use the same
  dark palette as the rest of the OpenMANET Argon theme. The application on
  port 8080 is not modified.
- A boot health report at `/tmp/openmanet-health` distinguishes storage/feed,
  BATMAN module/interface/hard-interface, bridge membership, peer,
  originator, Docker capability, and OpenTAKServer readiness.

## Validation completed on the build host

- `scripts/tests/test-rpi5-source.sh` — pass.
- Shell syntax checks for all new preinit, init, BATMAN repair, and health
  scripts — pass.
- `make defconfig` — pass for the Pi 5 board profile.
- `make target/linux/prepare V=sc` — pass; the prepared Pi 5 DTS no longer has
  `cgroup_disable=memory`.
- Full OpenWrt image build — pass, exit status 0. The final build installed the
  complete rootfs and generated factory/sysupgrade images for SquashFS and the
  standard ext4 alternative.
- Generated package feed inspection — pass: all release feeds use
  `aarch64_cortex-a72`; no unavailable bcm2712/a76 feed is emitted.
- Final kernel configuration inspection — pass: cgroups, memory accounting,
  F2FS security xattrs, Linux security, and OverlayFS are enabled.
- Final rootfs inspection — pass: the shipped SquashFS contains the dark home
  portal CSS, Docker `storage_driver 'vfs'`, OpenMANET BATMAN repair/health
  hooks, OpenTAKServer, and no OpenTAKServer reference to port 8080.
- Theme patch reverse-application test — pass; the patch is anchored to the
  actual Morse LuCI home package used by this image.

Final SquashFS artifacts and SHA-256 values:

| Artifact | SHA-256 |
|---|---|
| `openwrt-bcm27xx-bcm2712-rpi-5-squashfs-factory.img.gz` | `d1b7b3dc2512a42c573bf5d512b86d5d09961a3c2ac3c5416f4a31c7254d2729` |
| `openwrt-bcm27xx-bcm2712-rpi-5-squashfs-sysupgrade.img.gz` | `c14a493f5cce89e723c3943238469aee332f279b638f8be906e79c329fd8c79f` |

The `squashfs-factory` image is the correct artifact for a fresh SD-card
flash. The `squashfs-sysupgrade` image is for an existing compatible OpenWrt
installation.

## First startup

Flash the Pi 5 factory image, connect directly to Ethernet, and use
`http://10.41.254.1` or SSH as `root@10.41.254.1` with the initial blank
password. Set a root password, then open **Wizards → 802.11s Mesh** and choose
**Mesh Gate** on the node with the upstream Internet/LAN connection. Use the
same mesh ID, passphrase, region, and channel on all nodes. The wizard owns the
network credentials and the boot repair package only enforces the BATMAN-V
runtime baseline.

The first F2FS expansion may take time on a large card. Do not power off while
the first boot is resizing storage. Existing sysupgrade data under `/overlay`,
`/opt/docker`, and `/opt/opentakserver` is retained.

## OpenTAKServer

The `opentakserver` procd service starts Docker Compose after the Docker socket
is available. The first deployment needs Internet access to pull ARM64 images.
Use:

```sh
docker compose -f /opt/opentakserver/compose.yaml ps
logread -e opentakserver
```

Published endpoints are:

| Function | Port |
|---|---:|
| OpenTAKServer web UI | 8090 |
| OpenTAKServer API | 8091 |
| Plain CoT | 8088/TCP |
| TLS CoT for ATAK | 8089/TCP |
| RTMP / RTSP / HLS / MediaMTX | 1935 / 8554 / 8888 / 9997 |

Port 8080 is intentionally left to the separate application that owns it; it
is not an OpenMANET or OpenTAKServer endpoint.

## Hardware validation still required

The build host cannot prove electrical boot, SD-card partition growth, MM8108
USB enumeration, RF association, or Docker capability xattrs on a real F2FS
filesystem. Before production deployment, validate on the target Pi 5 with an
MM8108:

1. Boot a fresh card and confirm the overlay is F2FS and spans the card with
   `df -h /overlay` and `mount | grep ' /overlay '`.
2. Confirm `docker info` works, `docker info | grep Storage`, and run the
   health report. The disposable capability test must report `PASS`.
3. Run the OpenMANET wizard as Mesh Gate, then confirm `batctl n`, `batctl o`,
   and Internet reachability through the gateway.
4. Pull and start OpenTAKServer, then verify the 8090/8091/8088/8089 endpoints
   and persistence after reboot.
5. Repeat the storage test with the supported card sizes used in deployment.

The MM6108/SPI Pi 5 path remains a separate unresolved hardware issue; this
release is validated for the working MM8108/USB path.
