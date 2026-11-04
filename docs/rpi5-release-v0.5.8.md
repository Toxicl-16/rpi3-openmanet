# Raspberry Pi 5 OpenMANET firmware 0.5.8

This release starts from the v0.5.2 Pi 5 profile that provided the working
onboard BCM43455 Wi-Fi AP, then adds BATMAN-V `bat0`, OpenMANETD, OpenTAKServer,
and first-boot expansion of the writable SD-card space.

## Included

- Build with Parallel Morse Micro MM8108/MM6108 driver and firmware packages.
- Morse 802.11s mesh stack and OpenMANET mesh wizard.
- BATMAN-adv kernel module, BATMAN-V configuration, `batctl`, and LuCI BATMAN
  protocol support.
- Raspberry Pi 5 onboard BCM43455 SDIO Wi-Fi, firmware, Pi 5 NVRAM aliases,
  vendor brcmfmac modules, and WPA/hostapd support for the client AP.
- OpenMANETD and the OpenTAKServer Docker deployment definition.
- Required Docker cgroup, F2FS security, and file-capability support.
- First-boot LAN at `10.41.254.1` on `eth0`/`br-lan`.
- SquashFS factory/sysupgrade images with a 4 GiB initial Linux partition.
- First-boot expansion of the Linux partition and ext4/F2FS overlay to the
  end of the SD card.

PiAware and dump1090 are not included.

## Validation

- Source assertions and shell syntax checks — pass.
- Full build — required before publication of the release artifact.
- Image inspection must confirm the BCM43455 firmware/NVRAM and brcmfmac
  modules are present, the MM8108 firmware is present, BATMAN/OpenTAKServer
  packages are present, and no PiAware package is selected.

The Intel build host cannot verify physical Pi 5 SDIO attachment, AP beaconing,
Ethernet negotiation, MM8108 USB enumeration, real SD-card expansion, Docker
image pulls, or mesh traffic. Those checks require the Pi 5 hardware.

## First boot

Flash the SquashFS factory image, connect directly to Ethernet, and open
`http://10.41.254.1` or SSH to `root@10.41.254.1`. Set the root password and
use the Morse/OpenMANET wizard to configure the onboard Wi-Fi AP and select
Mesh Gate or Mesh Point. The BATMAN repair service waits for that explicit
role selection before creating `bat0` and its mesh hard interface.

OpenTAKServer is deployed under `/opt/opentakserver`; Docker images are pulled
on first start and its service configuration is in `/etc/config/opentakserver`.
