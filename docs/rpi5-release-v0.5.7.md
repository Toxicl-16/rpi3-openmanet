# Raspberry Pi 5 bare BATMAN firmware 0.5.7

This is a deliberately minimal recovery image based on the v0.5.2 Pi 5 boot
baseline. It is intended to validate boot, Ethernet/LuCI access, the Morse
MM8108 USB radio, BATMAN-V, and full SD-card use before optional services are
reintroduced.

## Included

- Build with Parallel Morse Micro MM8108/MM6108 driver and firmware packages.
- Morse 802.11s mesh stack and OpenMANET mesh wizard.
- BATMAN-adv kernel module, BATMAN-V configuration, `batctl`, and LuCI BATMAN
  protocol support.
- First-boot LAN at `10.41.254.1` on `eth0`/`br-lan`.
- SquashFS factory/sysupgrade images with a 4 GiB initial Linux partition.
- Source-level first-boot expansion of the Linux partition to the end of the
  SD card, with ext4 and F2FS overlay handling.

## Deliberately excluded

- Raspberry Pi 5 onboard BCM43455/brcmfmac SDIO Wi-Fi and its firmware/NVRAM.
  The MM8108 USB HaLow radio is the node’s radio path; this removes the
  `brcmfmac mmc1:0001:1` firmware-load failure from the active image.
- Docker, OpenTAKServer, OpenMANETD, and their cgroup/storage additions.
- PiAware, dump1090, and unrelated port-8080 applications.

## Validation

- Source assertions — pass.
- Shell syntax checks — pass.
- Full `make -j16 V=sc` build — pass.
- Image inspection — pass: v0.5.2-compatible command line, no brcmfmac files,
  MM8108 firmware present, BATMAN packages present, and no ext4 release image.
- Factory image SHA-256:
  `a1c65f5cf76821f36eba68e9161897d099afac0020fabfebd508083a8bfd0af8`
- Sysupgrade image SHA-256:
  `2420e1332d629d0b92081cfc8f58f28e36a3a6dc8591d819a7a578f1d7ce896c`

The build host cannot verify physical Pi 5 boot, Ethernet negotiation, MM8108
USB enumeration, real SD-card partition growth, or mesh traffic. Those checks
must be performed on the Pi 5 with the MM8108 module. This image intentionally
does not claim those hardware results until tested.

## First boot

Flash the SquashFS factory image, connect directly to Ethernet, and open
`http://10.41.254.1` or SSH to `root@10.41.254.1`. Set the root password and
use the Morse/OpenMANET mesh wizard to select Mesh Gate or Mesh Point. The
BATMAN repair service waits for that explicit role selection before creating
`bat0` and its mesh hard interface.
