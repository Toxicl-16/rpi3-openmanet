# Raspberry Pi 5 OpenMANET firmware 0.5.4

This release rebuilds the Build with Parallel Raspberry Pi 5 firmware with the
OpenMANET daemon, OpenMANET LuCI portal, OpenTAKServer deployment, and the Pi 5
first-boot Ethernet correction.

## Changes in this release

- Removed `CONFIG_TARGET_DEFAULT_LAN_IP_FROM_PREINIT` from the Pi 5 board
  profile. The global option generated a second late LAN script and could
  override or duplicate the board-specific OpenMANET LAN setup.
- Added the Raspberry Pi 5 board names to the preinit Ethernet selection so
  the recovery/preinit path consistently uses `eth0`.
- Kept the Pi 5 board network definition as the single normal-LAN source:
  `eth0`/`br-lan`, `10.41.254.1/24`, and the standard OpenWrt DHCP range.
- No PiAware, dump1090, port-8080 application, or optional Build with Parallel
  bundles were added.

The OpenMANET wizard remains the upstream `luci-app-ekhwizards` workflow, with
the OpenMANET dark theme. OpenTAKServer remains a shipped procd/Docker Compose
deployment; its web UI/API ports are 8090/8091 and its CoT ports are 8088/8089.

## Validation completed on the build host

- `git diff --check` — pass.
- `scripts/tests/test-rpi5-source.sh` — pass.
- Shell syntax checks for the changed preinit and test scripts — pass.
- `make defconfig V=s` — pass; the Pi 5 board profile no longer selects the
  duplicate preinit LAN generator.
- Full `make -j16 V=sc` image build — pass; no fatal make or missing-target
  errors were found in the build log.
- Factory and sysupgrade gzip artifacts — pass; sysupgrade metadata was
  extracted on disposable copies and identifies the three supported Pi 5
  boards.
- Release `sha256sums` — pass for all generated artifacts.
- Factory image layout — pass: 64 MiB FAT boot partition and 4 GiB Linux
  partition beginning at sector 147456.
- Shipped rootfs inspection — pass: Pi 5 network scripts, DHCP defaults,
  OpenMANET landing configuration, `openmanetd`, OpenTAKServer, Docker config,
  and BATMAN packages are present; duplicate `99-lan-ip` and PiAware are absent.

The build host cannot verify electrical boot, Ethernet link negotiation, SD-card
F2FS growth, MM8108 USB enumeration, RF association, Docker capability xattrs,
or multi-node mesh traffic. Those still require the supported Pi 5/MM8108
hardware. The known MM6108/SPI binding issue is unchanged.

## Artifacts

The SquashFS factory image is the artifact for a fresh SD-card flash. The
SquashFS sysupgrade image is for an existing compatible OpenWrt installation.

| Artifact | SHA-256 |
|---|---|
| `openwrt-bcm27xx-bcm2712-rpi-5-squashfs-factory.img.gz` | `507c5b2217bd2b8f68e52dd14d803359158653923ea161673f43ff1f8fe68801` |
| `openwrt-bcm27xx-bcm2712-rpi-5-squashfs-sysupgrade.img.gz` | `bc83126f54b352bb46136d01453e9d3380aa380ea8dbd3bb279111249b23eb1d` |
| `openwrt-bcm27xx-bcm2712-rpi-5-ext4-factory.img.gz` | `8da460c0f6acb057b070fbe97cab389808205382ed0741a27362579beb987a3f` |
| `openwrt-bcm27xx-bcm2712-rpi-5-ext4-sysupgrade.img.gz` | `6b147a43a52baaed2cbf6e290aa204a83d9fb592f869d34894f9404f7cb632de` |

## First boot

Connect a computer directly to the Pi 5 Ethernet jack and obtain an address by
DHCP. The node should be reachable at `http://10.41.254.1` or
`root@10.41.254.1`; the fresh image has a blank root password. Set the root
password first, then open **Wizards → 802.11s Mesh** and select **Mesh Gate**
for the node providing the upstream connection.

If DHCP does not assign a lease, temporarily set the computer to
`10.41.254.2/24` and test `10.41.254.1`. This is a diagnostic fallback, not a
required image configuration. On the Pi, inspect `ip -br addr`, `uci show
network`, `logread -e netifd -e dnsmasq`, and `logread -e macb` before changing
the generated network configuration.
