# OpenMANET node startup

This checklist applies to the active Raspberry Pi 5 image with a Gateworks
MM8108 USB HaLow module. The Pi 3B+ image is an archived reference and does
not use this Pi 5 startup profile.

## First boot

1. Flash the `squashfs-factory` image from the [latest GitHub release](https://github.com/Toxicl-16/rpi3-openmanet/releases/latest).
2. Connect a computer directly to the Pi 5 Ethernet port.
3. Open `http://10.41.254.1` or SSH to `root@10.41.254.1`. The fresh image has a blank root password.
4. Set the root password from the LuCI banner.
5. Open **Wizards → 802.11s Mesh**.
6. Set the same Mesh ID, passphrase, and operating frequency on every node.
7. Choose **Mesh Gate** for the node connected to the Internet or upstream LAN. Choose **Mesh Point** for an extender node.
8. Apply the wizard configuration and wait for the network services to restart.

On the first boot from a factory image, the firmware expands the root
partition and creates or resizes the F2FS writable overlay before normal
startup. The first boot can take longer on a large SD card; do not remove
power during that operation. A sysupgrade keeps the existing `/overlay`,
Docker data, and OpenTAKServer data.

For a Mesh Gate, select the upstream Ethernet interface. Use **Router** on a
trusted upstream network. Use **Router with Firewall** when the Ethernet port
connects directly to an untrusted Internet connection. The OpenMANET wizard
configures the BATMAN-adv gateway announcement and mesh interface.

For a Mesh Point, **Bridge** lets downstream devices receive addresses from
the gate. **Extender** creates a separate downstream DHCP/NAT network.

## Verify the node

Run these commands over SSH after applying the wizard:

```sh
logread -e morse
logread -e mesh11sd
logread -e openmanetd
ip -br link
iw dev
batctl n
batctl o
pgrep -af openmanetd
cat /tmp/openmanet-health
```

The HaLow radio should be present in `iw dev`, the mesh peer should appear in
`batctl n`, and the BATMAN originator table should populate in `batctl o`.
The health report separately identifies the BATMAN module, `bat0`, its hard
interface, bridge membership, established peers, learned originators, Docker
capability xattrs, and OpenTAKServer readiness. A peer/originator warning is
expected before another mesh node has joined; storage, interface, and bridge
failures require correction.

## MM8108 USB radio path workaround

If LuCI reports the radio as down and `logread` contains `Phy not found`, run
the following once after boot, then bring Wi-Fi up:

```sh
FULL_PATH=$(for p in /sys/class/ieee80211/phy*; do
    link=$(readlink "$p")
    echo "$link" | grep -q '3-1:1.0/ieee80211' && echo "$link" | sed 's|^../../devices/||' && break
done)
uci set wireless.radio0.path="$FULL_PATH"
uci commit wireless
wifi up
```

If `wifi detect` created a duplicate radio, remove the duplicate before
committing the configuration:

```sh
uci delete wireless.radio2
uci delete wireless.default_radio2
uci commit wireless
```

## OpenTAKServer

OpenTAKServer starts automatically after Docker is ready. The first startup
needs Internet access to pull the ARM64 containers. Monitor it with:

```sh
logread -e opentakserver
docker ps
docker compose -f /opt/opentakserver/compose.yaml ps
```

Use the web UI at `http://NODE_IP:8090` to create users and configure the TAK
server. The API is on port `8091`. Configure ATAK with the TLS Cursor-on-Target
endpoint on port `8089`; port `8088` is the plain TCP CoT endpoint.

The optional media endpoints are RTMP `1935`, RTSP `8554`, HLS `8888`, and the
MediaMTX management endpoint `9997`. The database and RabbitMQ services remain
private inside the Docker network.

If a custom database password is required, edit
`/opt/opentakserver/ots_config.env` before the first deployment and restart the
service:

```sh
/etc/init.d/opentakserver restart
```

## Existing installations and the UI theme

A sysupgrade preserves `/etc/config/luci`. If an older image still shows the
Morse colors, set the OpenMANET theme explicitly and hard-refresh the browser:

```sh
uci set luci.main.mediaurlbase='/luci-static/openmanetargon'
uci commit luci
/etc/init.d/uhttpd restart
```

For a completely clean configuration, use the factory image instead of a
sysupgrade image.
