# OpenMANET HaLow Firmware for Raspberry Pi

[![OpenWrt 23.05](https://img.shields.io/badge/OpenWrt-23.05-blue)](https://github.com/MorseMicro/openwrt)
[![Kernel 6.6](https://img.shields.io/badge/Linux%20kernel-6.6-lightgrey)](https://github.com/openwrt/openwrt)
[![Raspberry Pi 5](https://img.shields.io/badge/Raspberry%20Pi-5-c51a4a)](https://www.raspberrypi.com/products/raspberry-pi-5/)
[![Morse Micro HaLow](https://img.shields.io/badge/Morse%20Micro-HaLow-6f42c1)](https://www.morsemicro.com/)
[![Build walkthrough](https://img.shields.io/badge/YouTube-build%20walkthrough-red)](https://youtu.be/2y5DjqLjSXw)

![Haven Pi 5 — Raspberry Pi 5 with Morse Micro HaLow radio, UPS HAT, and battery stack](docs/haven-pi5.png)

OpenWrt-based Morse Micro HaLow firmware for Raspberry Pi MANET nodes. The active build targets the Raspberry Pi 5 and adds `openmanetd`, Docker, and an OpenTAKServer deployment on top of Build with Parallel's working MM8108 USB firmware. The repository also retains documentation for the earlier Raspberry Pi 3B+ OpenMANET image.

## Supported targets

| Target | Status | Radio path | Documentation |
|---|---|---|---|
| Raspberry Pi 5 (`bcm2712`) | Active build target; image built and SquashFS verified | Morse Micro MM8108 over USB | [Pi 5 guide](docs/rpi5.md) |
| Raspberry Pi 3B+ (`bcm2710`) | Archived OpenMANET target and hardware reference | Morse Micro MM8108 over USB | [Pi 3B+ guide](docs/rpi3b-plus.md) |

The Pi 5 image is the firmware currently produced by this checkout. The Pi 3B+ page records the previously published image and its verification metadata; it is kept separate from the Pi 5 build profile.

This repo is a community backport. The [Morse Micro OpenWrt SDK](https://github.com/MorseMicro/openwrt) ships on OpenWrt 23.05 (kernel 5.15) and supports Pi 4. The bcm2712/RP1 hardware definitions from upstream OpenWrt 24.10 (kernel 6.6) have been vendored back so the same Morse SDK can build for Pi 5.

> **Just want to flash?** Download the pre-built Raspberry Pi 5 image from the [Releases](../../releases) section — no build required.

> **Field notes & test results:** The [Haven Guide](https://buildwithparallel.com/products/haven) has real-world range tests, hardware setup notes, and deployment tips from building with this firmware. Not required to build or flash — just useful if you want to go deeper.

> **Note:** This repo exists as a bridge. When Morse Micro releases their OpenWrt 24.x SDK — which is expected to include native Raspberry Pi 5 support — this repo will likely be superseded by the official upstream fork. Until that happens, this backport is the way to get HaLow running on Pi 5.

**Software Specifications**
- Morse Micro OpenWrt SDK, 23.05.5 base
- Linux kernel 6.6 (vendored from openwrt-24.10)
- mac80211 backports 6.12.61
- Morse Micro driver 1.16.4

## About

This firmware is part of [Build with Parallel](https://buildwithparallel.com/), a project focused on practical off-grid communications, resilient mesh networking, and field-ready Raspberry Pi builds.

## Project Links

| Link | What it is |
|---|---|
| [Releases](../../releases) | Pre-built Raspberry Pi 5 firmware images |
| [Build walkthrough video](https://youtu.be/2y5DjqLjSXw) | End-to-end source build, customization, and SD-card flashing |
| [Haven Guide](https://buildwithparallel.com/products/haven) | Field notes, hardware setup, range tests, and deployment notes |
| [Haven mesh setup scripts](https://github.com/buildwithparallel/haven-manet-ip-mesh-radio) | Gate/point node setup scripts for the wider Haven mesh topology |
| [Build with Parallel](https://buildwithparallel.com) | Project site and broader Haven updates |
| [Data Slayer on YouTube](https://www.youtube.com/@DataSlayerMedia) | Build videos, demos, and field updates |
| [Data Slayer on X](https://x.com/data_slayer) | Short-form updates and project notes |

## Supported Hardware

### HaLow radios

| Device                          | Chip   | Interface         | Status                     |
|---------------------------------|--------|-------------------|----------------------------|
| Seeed Studio HaLow HAT          | MM6108 | SPI               | Does not bind yet          |
| Gateworks MM8108                | MM8108 | USB (HAT-to-Pi)   | Working                    |

The original goal is the Seeed Studio HaLow HAT on Pi 5 over SPI — that path is still open. The DesignWare SPI / RP1 DMA / Morse SPI overlay are in place but the MM6108 chip isn't binding yet on Pi 5. As a working alternative, the MM8108 currently runs on Pi 5 via a USB cable from the HaLow board to the Pi.

### Regular Wi-Fi

| Device                          | Chip          | Interface | Status         |
|---------------------------------|---------------|-----------|----------------|
| Pi 5 onboard Wi-Fi              | BCM43455      | SDIO      | Included       |
| Panda Wireless USB dongle       | Ralink RT5370 | USB       | Included       |

Drivers and firmware for both are in the build (`kmod-brcmfmac` + `cypress-firmware-43455-sdio` for onboard, `kmod-rt2800-usb` for the dongle). Configure them at runtime via LuCI or `/etc/config/wireless`.

## Included Add-Ons

Beyond the base Morse HaLow stack, this build ships a curated set of extras ready to use out of the box:

- **Mesh networking** — `batman-adv` + `batctl` Layer-2 mesh with LuCI integration, plus `mesh11sd` for 802.11s
- **VPN** — WireGuard (kernel module + LuCI proto) and Tailscale client/daemon (compatible with Headscale for off-grid use)
- **ADS-B aircraft tracking** — RTL-SDR library, `dump1090` decoder, and Python 3 with `cryptography` for `adsbcot` (Cursor-on-Target feed)
- **LoRa / Reticulum sidecar** — Python 3 with `pyserial` and `netifaces`; USB-ACM and USB-serial drivers for:
  - Heltec V1 (nRF52) / V4 (ESP32-S3)
  - RAK4631 (nRF52840)
  - Seeed Xiao ESP32-S3
  - Walter (ESP32-S3)
  - Muzi Works Base Duo
  - Null Hop Mesh Toad (CH341)
- **Network debugging** — `tcpdump`, `iperf3`, `mtr`, `nmap`, full `iw`, `lsusb`
- **Web UI** — LuCI with Morse Argon theme, first-boot setup wizard, WireGuard and batman-adv config UIs
- **General utilities** — Bash, `curl` (TLS + CA bundle), `nano`, `htop`, `screen`, mDNS (`umdns`)

## Building

The `v0.4.0-alpha` images were built on a Google Compute Engine VM running Ubuntu 22.04.5 LTS (`x86_64`), with 96 vCPUs, approximately 94 GiB of usable RAM, and a 500 GiB Extreme persistent disk for fast read/write operations during compilation. These are the tested build host specifications, not minimum requirements. `make -j$(nproc)` uses every available vCPU; reduce parallelism on machines with less RAM.

For a visual walkthrough of the full process, including building the OpenWrt Morse Micro firmware from source, applying customization, and flashing the resulting image to an SD card, see the [build and flash video](https://youtu.be/2y5DjqLjSXw).

### 1. Install build dependencies

```
sudo apt update
sudo apt install build-essential clang flex g++ gawk gcc-multilib g++-multilib git gettext \
  libncurses5-dev libssl-dev python3-setuptools rsync unzip zlib1g-dev swig file wget \
  libnl-3-dev libnl-genl-3-dev pkg-config
```

### 2. Clone

```
git clone -b main https://github.com/Toxicl-16/rpi3-openmanet.git
sudo chown -R $USER:$USER rpi3-openmanet
cd rpi3-openmanet
```

The `chown` ensures every file in the cloned tree is owned by your user. OpenWrt's build system refuses to run as root and trips over root-owned files, so this avoids permission errors later.

### 3. Update and install feeds

```
./scripts/feeds update -a
./scripts/feeds install -a
./scripts/apply-build-fixes.sh
```

This pulls the Morse HaLow, OpenWrt, and LuCI package feeds (defined in `feeds.conf.default`) and registers their packages with the build system.

The Morse, LuCI, and prpl feeds are pinned to matching 2.9-dev snapshots, including Morse driver/firmware 1.16.4. The fix script adapts the driver and LuCI to this SDK and removes two unused prpl UPnP forks that cause Kconfig dependency loops. Run the script again after updating feeds; repeated runs are safe.

The Rust recipe is maintained in-tree at `package/lang/rust/` and is automatically preferred over the packages feed recipe. It builds LLVM from the hash-verified Rust release sources, avoiding the expired Rust CI LLVM download without a manual patch. The first build takes longer; subsequent builds reuse the compiled toolchain. Do not force-install the feed's Rust package with `./scripts/feeds install -f rust`, since that overrides this fix. For existing checkouts, the fix script removes the old Rust feed link so the in-tree recipe is used.

### 4. Select the active Pi 5 config

```
cp boards/ekh-bcm2712/target_diffconfig .config
make defconfig
```

`target_diffconfig` selects the rpi-5 device, the Morse HaLow driver/firmware/CLI, the S1G hostapd/wpa_supplicant stack, mesh, and LuCI apps. `make defconfig` expands it into a full `.config`, filling in defaults.

### 5. Download sources

```
make -j$(nproc) download
```

### 6. Build

```
set -o pipefail
make -j$(nproc) V=sc 2>&1 | tee log.txt
```

`V=sc` enables verbose compile output; `tee log.txt` captures it for troubleshooting.

When the build finishes, the Pi 5 image is under:

```
bin/targets/bcm27xx/bcm2712/*rpi-5-squashfs-*.img.gz
```

Flash the `*-factory.img.gz` file to an SD card with [Raspberry Pi Imager](https://www.raspberrypi.com/software/) (choose "Use custom") and boot the Pi 5.

## OpenMANET and OpenTAKServer services

The Pi 5 profile includes the Morse MM8108 driver and firmware, `openmanetd`, Docker, Docker Compose, containerd, and runc. OpenTAKServer is shipped as an OpenWrt `procd` service with its Compose deployment under `/opt/opentakserver`.

OpenTAKServer application images are pulled as ARM64 containers on first start. Internet access is therefore required on the first service start unless an offline image bundle is placed at `/mnt/opentakserver/offline-images.tar.zst` before enabling the service. The root filesystem allocation in the Pi 5 profile is 4 GB to leave room for those container layers.

## First boot

The node does **not** use `192.168.1.1`. That address collides with a typical home router. Like an OpenMANET fresh flash, first-boot LAN is:

- **Address:** `10.41.254.1`
- **Subnet:** `10.41.254.0/24`
- **DHCP:** the node hands out `10.41.254.100`–`10.41.254.249`

Connect your computer **directly** to the Pi 5 Ethernet jack (do not put the node on your existing LAN). Set the computer to obtain an IP automatically — it should get a `10.41.254.x` lease. Then open LuCI at [http://10.41.254.1](http://10.41.254.1) or SSH as `root@10.41.254.1` (blank password).

If you plug the node into a home router instead, your computer stays on `192.168.1.x` and cannot reach `10.41.254.1` without a static route.

Open LuCI and use **Wizard** in the top bar. Set a root password from the yellow banner first, then run the wizard to pick region and mode.

## Setting the Region

Go to **Network → Wireless**, click **Edit** on each radio, ensure the correct **Country Code** is selected, and click **Save**. Then return to the main Wireless page and click **Save & Apply** to apply the settings for all radios. The country code warning should then clear.

## Upstream sources

- Morse Micro OpenWrt SDK: https://github.com/MorseMicro/openwrt (23.05.5 base, branch `mm/v23.05.5`)
- Morse Micro package feed: https://github.com/MorseMicro/morse-feed
- Morse Micro driver: https://github.com/MorseMicro/morse_driver
- Upstream OpenWrt 24.10 (Pi 5 hardware donor): https://github.com/openwrt/openwrt
