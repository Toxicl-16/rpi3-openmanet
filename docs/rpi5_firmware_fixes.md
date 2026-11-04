# OpenMANET Raspberry Pi 5 — Comprehensive Firmware Repair and Release Task

## Mission

Audit, repair, improve, and release the custom OpenMANET firmware for the Raspberry Pi 5.

Several critical issues were discovered during real-world deployment. Some were successfully repaired manually, while others remain unresolved. Implement permanent, source-level fixes so the next firmware release works correctly immediately after flashing, without requiring users to manually repair network configurations, resize filesystems, change package repositories, or troubleshoot Docker compatibility.

**The objective is a stable, reproducible, production-ready OpenMANET Raspberry Pi 5 firmware release that matches the functionality and appearance of the original OpenMANET implementation while retaining Raspberry Pi 5 hardware and gateway-specific features.**

Do not simply provide instructions or suggest manual commands. Inspect the actual repository, implement the fixes, build the firmware, and validate the resulting artifacts wherever the environment permits.

For validation that requires unavailable physical hardware, provide explicit test procedures and mark the results as unverified. Do not claim that a test passed unless it was executed.

---

# 1. Target Platform and Reference System

## Target: Raspberry Pi 5

The problematic firmware has the following characteristics:

| Component | Configuration |
|---|---|
| Hardware | Raspberry Pi 5 |
| SoC | BCM2712 |
| CPU | ARM Cortex-A76 |
| Package architecture | `aarch64_cortex-a76` |
| OpenWrt base | 23.05.5 |
| Kernel | 6.6.133 |
| Root filesystem | SquashFS |
| Writable filesystem | F2FS |
| Root storage | SD card |
| Docker data root | `/opt/docker` |
| Docker storage driver | `vfs` |
| Mesh routing | BATMAN-adv 2025.4 |
| Mesh interface | `bat0` |
| Wireless mesh interface | `wlan0` |
| Client bridge | `br-ahwlan` |
| Local AP interfaces | `phy2-ap0`, `wlan1` |
| Ethernet uplink | `eth0` |
| Management service | `openmanetd` |
| Mesh service | `mesh11sd` |

## Working reference system

A Raspberry Pi 3 running the original OpenMANET firmware was used as a working configuration reference.

| Component | Configuration |
|---|---|
| Hardware | Raspberry Pi 3 |
| Firmware | OpenMANET 24.10 release 1.8.1 |
| Kernel | 6.6.138 |
| Architecture | `aarch64_cortex-a53` |
| BATMAN version | 2025.4 |
| Wireless mesh interface | `wlh0` |
| BATMAN hard interface | `batmesh0` |
| BATMAN interface | `bat0` |
| Client bridge | `br-ahwlan` |

Use the original implementation to determine the expected BATMAN configuration, web portal styling, mesh behavior, and configuration conventions.

Do not blindly copy hardware-specific settings, radio paths, interface names, network addresses, or mesh-point routing behavior from the Raspberry Pi 3 to the Raspberry Pi 5.

Investigate whether adopting a newer compatible OpenWrt base would resolve compatibility problems, but do not migrate the base unless all required Raspberry Pi 5, OpenMANET, Morse/HaLow, and Docker functionality can be preserved.

---

# 2. P0 — Repair BATMAN-adv Mesh Initialization

## Problem

The Raspberry Pi 5 firmware initially displayed the `bat0` interface in LuCI as an unsupported protocol.

The following packages were already installed:

```text
batctl-default 2025.4-2
kmod-batman-adv 6.6.133+2025.4-2
luci-proto-batman-adv
```

The BATMAN kernel module loaded correctly:

```text
batman_adv 208896 0
```

LuCI's BATMAN protocol handlers existed:

```text
/www/luci-static/resources/protocol/batadv.js
/www/luci-static/resources/protocol/batadv_hardif.js
/www/luci-static/resources/protocol/batadv_vlan.js
```

Netifd also recognized the relevant protocols:

```text
batadv
batadv_hardif
batadv_vlan
```

Therefore, the root cause was not a missing package.

## Root cause

The initial UCI configuration was incomplete:

```text
network.bat0=interface
network.bat0.multicast_mode='0'
```

The firmware also exposed:

```text
network.bat0.disabled='1'
```

The `bat0` interface was absent from the Linux network interfaces.

Netifd reported:

```json
{
  "up": false,
  "available": false,
  "proto": "none",
  "errors": [
    {
      "subsystem": "interface",
      "code": "NO_DEVICE"
    }
  ]
}
```

Running `batctl` failed because no BATMAN device existed.

## Initial repair

Adding:

```bash
uci set network.bat0.proto='batadv'
uci set network.bat0.routing_algo='BATMAN_V'
uci commit network
ifup bat0
```

successfully created the `bat0` device.

However, it initially had no active BATMAN hard interfaces, preventing mesh traffic from passing through it.

## Required firmware fix

Generate a complete BATMAN configuration automatically for each device role.

The Raspberry Pi 5 baseline configuration should resemble:

```uci
config interface 'bat0'
    option proto 'batadv'
    option routing_algo 'BATMAN_V'
    option multicast_mode '0'
    option bridge_loop_avoidance '1'
    option hop_penalty '30'
    option orig_interval '1000'
    option distributed_arp_table '1'

config interface 'batmesh0'
    option proto 'batadv_hardif'
    option master 'bat0'
```

Verify all optional settings against the exact BATMAN-adv version and netifd protocol handler rather than copying them indiscriminately.

Do not generate:

```text
network.bat0.disabled='1'
```

when BATMAN mesh routing is enabled.

If the user explicitly disables mesh routing, preserve that intentional configuration.

---

# 3. P0 — Correct the Mesh Wireless and Bridge Topology

## Original problem

The Raspberry Pi 5 wireless configuration contained:

```text
wireless.default_radio0.mode='mesh'
wireless.default_radio0.network='ahwlan'
```

The 802.11s mesh radio was therefore directly bridged into the client network instead of being attached to BATMAN-adv.

Original runtime bridge ports:

```text
br-ahwlan:
    phy2-ap0
    wlan0
    wlan1
```

This bypassed the intended BATMAN routing layer.

## Working reference configuration

The Raspberry Pi 3 uses:

```uci
config interface 'batmesh0'
    option proto 'batadv_hardif'
    option master 'bat0'
```

Its wireless mesh interface references:

```text
network='batmesh0'
```

Its bridge contains `bat0`, while its wireless mesh interface is attached to BATMAN.

## Required topology

```text
                802.11s Mesh Radio
                       |
                 Wireless Mesh
                       |
                batadv_hardif
                    batmesh0
                       |
                      bat0
                    BATMAN_V
                       |
                   br-ahwlan
                    /     \
                Local APs  Clients
```

The firmware must configure the wireless mesh interface to use the BATMAN hard-interface network:

```text
wireless.default_radio0.network='batmesh0'
wireless.default_radio0.mesh_fwding='0'
```

The client bridge must include `bat0`.

The physical 802.11s mesh interface must not be directly bridged into `br-ahwlan`.

## Successful repair performed

The Raspberry Pi 5 was repaired by configuring:

```bash
uci -q delete network.bat0.disabled

uci set network.bat0.proto='batadv'
uci set network.bat0.routing_algo='BATMAN_V'
uci set network.bat0.multicast_mode='0'
uci set network.bat0.bridge_loop_avoidance='1'
uci set network.bat0.hop_penalty='30'
uci set network.bat0.orig_interval='1000'
uci set network.bat0.distributed_arp_table='1'

uci set network.batmesh0='interface'
uci set network.batmesh0.proto='batadv_hardif'
uci set network.batmesh0.master='bat0'

uci set wireless.default_radio0.network='batmesh0'
uci set wireless.default_radio0.mesh_fwding='0'

uci add_list network.@device[0].ports='bat0'
```

Equivalent settings were activated successfully.

## Verified result

After correction:

```bash
batctl meshif bat0 if
```

Returned:

```text
wlan0: active
```

The wireless mesh device reported:

```text
wlan0:
    UP
    LOWER_UP
    master bat0
```

The BATMAN device reported:

```text
bat0:
    UP
    LOWER_UP
    mtu 1460
    master br-ahwlan
```

Bridge members became:

```text
bat0
phy2-ap0
wlan1
```

This confirms that the local BATMAN topology was successfully repaired.

## Device-role requirements

The build must distinguish mesh gateways from mesh points.

For gateways:

- Keep the upstream routed Ethernet connection separate from the client bridge.
- Preserve WAN DHCP and NAT behavior.
- Preserve management access.
- Determine appropriate BATMAN gateway-mode settings.

For mesh points:

- Permit intended client-side Ethernet bridging.
- Use the correct BATMAN gateway-client behavior.
- Preserve mesh-point-specific IP configuration.

The working Raspberry Pi 3 has `eth0` inside its bridge and uses `gw_mode='client'`. These settings must not be blindly copied onto the Pi 5 gateway.

## Acceptance criteria

After first boot:

```bash
ubus call network.interface.bat0 status
batctl meshif bat0 if
ip link show bat0
ls /sys/class/net/br-ahwlan/brif/
```

Must confirm:

- `bat0` is present and operational.
- The protocol is `batadv`.
- BATMAN-V is selected.
- A mesh hard interface is active.
- The hard interface is attached to `bat0`.
- `bat0` is attached to `br-ahwlan`.
- The physical mesh interface is not directly bridged.
- Local AP functionality remains operational.
- Gateway Ethernet routing remains intact.

---

# 4. P1 — Verify Two-Node Mesh Connectivity

The repaired Raspberry Pi 5 has a functional local BATMAN interface, but no BATMAN neighbors were visible during testing.

Output:

```text
[B.A.T.M.A.N. adv 2025.4-openwrt-2,
 MainIF/MAC: wlan0/... BATMAN_V]

Neighbor  last-seen  speed  IF
```

The reference Raspberry Pi 3 also showed no neighbors during its diagnostic capture.

This does not invalidate the local BATMAN repair, but end-to-end mesh connectivity remains unverified.

## Required tests

Verify:

- Radio compatibility.
- Matching mesh IDs.
- Matching encryption credentials.
- Regulatory domain compatibility.
- Compatible channel and width.
- Successful 802.11s peering.
- BATMAN neighbor discovery.
- BATMAN originator learning.
- Layer 2 forwarding between nodes.
- Multi-hop forwarding where supported.
- Traffic between mesh clients.
- Gateway access across the mesh.

Useful commands:

```bash
iw dev wlan0 station dump
batctl meshif bat0 if
batctl meshif bat0 n
batctl meshif bat0 o
```

On the Raspberry Pi 3, the mesh interface was `wlh0`.

Avoid hardcoding either interface name into the build.

Also investigate the management IP conflict warnings observed on the reference Raspberry Pi 3:

```text
WRN mgmt IP conflict
```

The reference logs included repeated warnings involving a duplicate `10.41.63.189` management address.

Treat IP collision detection as a separate concern from BATMAN interface creation.

---

# 5. P0 — Repair OpenWrt Package Repository Configuration

## Original problem

The Raspberry Pi 5 firmware used OpenWrt 23.05.5 with custom target and architecture values:

```text
bcm27xx/bcm2712
aarch64_cortex-a76
```

Its configured package feeds included:

```text
https://downloads.openwrt.org/releases/23.05.5/targets/bcm27xx/bcm2712/packages
```

And:

```text
https://downloads.openwrt.org/releases/23.05.5/packages/aarch64_cortex-a76/base
```

The configured official repositories were unavailable.

Running:

```bash
opkg update
```

failed across the default feeds.

## Temporary workaround

The system was temporarily configured to accept selected OpenWrt Cortex-A72 packages:

```text
arch all 1
arch noarch 1
arch aarch64_cortex-a72 5
arch aarch64_cortex-a76 10
```

Repositories used included:

```text
https://downloads.openwrt.org/releases/23.05.5/packages/aarch64_cortex-a72/base
```

And:

```text
https://downloads.openwrt.org/releases/23.05.5/packages/aarch64_cortex-a72/packages
```

This enabled installation of:

```text
parted
libparted
f2fs-tools
f2fsck
```

It also resolved dependencies involving:

```text
libreadline8
libncurses6
terminfo
```

This is a workaround, not a validated production package-management solution.

## Required firmware changes

Audit:

```text
/etc/opkg.conf
/etc/opkg/distfeeds.conf
/etc/opkg/customfeeds.conf
```

Fix the build system so the generated feeds refer to existing, compatible repositories.

Acceptable approaches:

1. Publish native Raspberry Pi 5 OpenMANET package repositories.
2. Select a validated, supported userspace package ABI.
3. Build and publish matching packages directly from the firmware build.

Requirements:

- Every configured repository must exist.
- Package architecture must be compatible with the image.
- Kernel modules must match the exact kernel ABI.
- Repository signatures and keys must be configured correctly.
- Avoid cross-release dependencies.
- Do not rely on forced architecture or dependency options.
- Preserve custom OpenMANET and Morse packages.

Include essential maintenance tools or make them reliably installable.

## Acceptance criteria

```bash
opkg update
opkg print-architecture
opkg info parted
opkg info f2fs-tools
```

All package feeds must update successfully without broken URLs.

---

# 6. P1 — Automatically Expand SD Card Storage and F2FS Overlay

## Original problem

The Raspberry Pi 5 used a 32 GB SD card but only approximately 4 GB of writable storage.

Original layout:

```text
/dev/mmcblk0       29.5 GiB
/dev/mmcblk0p1       64 MiB
/dev/mmcblk0p2        4 GiB
/dev/loop0          ~3.9 GiB
```

The firmware uses:

- Read-only SquashFS.
- Writable F2FS overlay.
- Overlay mounted through a loop device.
- Docker storage under `/opt/docker`.

Docker installation initially failed because of insufficient storage.

## Manual partition fix

The second partition was expanded using:

```bash
parted -s /dev/mmcblk0 resizepart 2 100%
```

After reboot:

```text
mmcblk0p2    30892032 KiB blocks
loop0        30808448 KiB blocks
```

However, the F2FS filesystem itself still reported approximately 3.9 GB.

## F2FS filesystem layout

The observed firmware used:

```text
Backing partition: /dev/mmcblk0p2
F2FS offset:       85590016 bytes
Loop sectors:      61616896
```

The offset is relative to the second partition.

**Do not hardcode this offset. It may change when the SquashFS image changes.**

## Manual filesystem repair

Attempting to resize the mounted F2FS overlay failed:

```text
Info: Mounted device!
Info: Check FS only on RO mounted device
Error: Failed to open the device!
```

The SD card was moved into a Kali Linux virtual machine.

An F2FS loop device was created using the correct offset.

The first offline resize failed because F2FS required recovery from an unclean checkpoint:

```text
Mount unclean image to replay log first
```

The filesystem was mounted read-write and cleanly unmounted to replay its log.

Then:

```bash
resize.f2fs /dev/loop0
```

completed successfully.

Final live-device filesystem size:

```text
/dev/loop0          29.4G
overlayfs:/overlay  29.4G
```

Free storage was subsequently confirmed at approximately 23.1 GB.

## Required firmware implementation

Implement automatic first-boot SD-card expansion.

The process must:

1. Detect the actual root storage device.
2. Detect card capacity.
3. Identify the relevant root partition.
4. Preserve the existing partition start sector.
5. Extend the partition into available space.
6. Reboot or reload the partition table safely.
7. Determine the F2FS offset dynamically.
8. Ensure F2FS is unmounted before offline resizing.
9. Handle F2FS recovery and checkpoint requirements.
10. Resize the F2FS filesystem to the available capacity.
11. Preserve all overlay contents.
12. Avoid running unnecessary resize operations on subsequent boots.
13. Handle unexpected power loss safely.
14. Preserve Docker data and OpenMANET configurations.

Investigate an initramfs or early-boot maintenance mechanism.

Do not attempt offline F2FS resizing against a mounted root overlay.

## Acceptance criteria

Test freshly flashed SD cards of at least:

- 16 GB.
- 32 GB.
- 64 GB.

Confirm the writable filesystem uses the available space and retains all data across reboots and firmware upgrades.

---

# 7. P0 — Fix Docker File-Capability Support

## Current unresolved problem

After expanding the SD card, Docker successfully downloaded much more of the OpenTAKServer stack, but image extraction failed:

```text
failed to register layer:
lsetxattr security.capability /usr/bin/ping:
operation not supported
```

Docker runtime:

```text
Storage Driver: vfs
Docker Root Dir: /opt/docker
```

Filesystem:

```text
/dev/loop0          29.4G
overlayfs:/overlay  29.4G
```

The writable root is F2FS, exposed through OverlayFS.

## Suspected cause

The kernel or filesystem configuration may lack the extended-attribute security support required by Docker to apply file capabilities.

Investigate:

```text
CONFIG_F2FS_FS_XATTR
CONFIG_F2FS_FS_SECURITY
CONFIG_SECURITY
CONFIG_SECURITY_FILE_CAPABILITIES
```

Determine the corresponding OpenWrt kernel configuration options and whether those options are enabled in the generated Linux kernel configuration.

An attempt to read `/proc/config.gz` produced no output, so the kernel configuration was not conclusively established.

**The F2FS security-attribute diagnosis is a strong hypothesis, not yet a confirmed root cause.**

## Required investigation

Reproduce the failure outside Docker using a disposable file on the Docker storage filesystem.

Where available:

```bash
cp /bin/busybox /opt/docker/cap-test
setcap cap_net_raw+ep /opt/docker/cap-test
getcap /opt/docker/cap-test
rm -f /opt/docker/cap-test
```

Also test the same operations on the underlying F2FS mount to distinguish underlying filesystem limitations from OverlayFS behavior.

Check:

- Kernel F2FS security-xattr configuration.
- OverlayFS extended-attribute support.
- Linux file-capability support.
- Filesystem mount options.
- Docker storage-driver configuration.
- Container extraction behavior.
- Relevant kernel and Docker logs.

Fix the actual cause in the firmware source.

## Preferred fix

If the kernel lacks F2FS security-xattr support, enable the necessary kernel configuration and rebuild.

If the F2FS/OverlayFS architecture remains incompatible with Docker's requirements, investigate placing Docker storage on a dedicated ext4 filesystem.

Any alternative must preserve:

- SquashFS firmware design.
- Persistent Docker volumes.
- SD-card expansion.
- Existing OpenMANET settings.
- Upgrade behavior.

## Docker storage-driver review

The firmware currently uses:

```text
vfs
```

Investigate why the driver was selected.

Evaluate whether a more efficient and fully supported driver is appropriate for the chosen filesystem and kernel.

Do not switch storage drivers without planning how existing container data is preserved or migrated.

## Acceptance criteria

The firmware must successfully execute:

```bash
cd /opt/opentakserver

docker compose pull
docker compose up -d
docker compose ps
```

All required images must register successfully without:

```text
lsetxattr security.capability:
operation not supported
```

Verify container startup, volume persistence, database health, and behavior after reboot.

---

# 8. P1 — OpenTAKServer Integration and Docker Stability

The Raspberry Pi 5 gateway is intended to host OpenTAKServer.

The deployment includes services such as:

```text
ots
ots-webui
ots-db
ots-cot-parser
ots-eud-handler
ots-eud-handler-ssl
mediamtx
rabbitmq
```

## Required changes and validation

Ensure the firmware supports:

- Complete Docker image downloads.
- Docker image layer registration.
- Linux file capabilities.
- Persistent databases and volumes.
- Container networking.
- Container restart policies.
- Functional access from the OpenMANET mesh.
- Appropriate firewall rules.
- Storage monitoring.
- Log rotation.
- Reliable behavior after restart.

Confirm Docker's networking does not disrupt the BATMAN bridge or gateway routing.

The Docker daemon also reported:

```text
WARNING: No memory limit support
WARNING: No swap limit support
```

Audit the kernel cgroup configuration and determine whether memory and swap accounting should be enabled.

Do not confuse these warnings with the separate file-capability extraction failure.

---

# 9. P2 — Fix OpenMANET Portal Dark Theme on Raspberry Pi 5

## Problem

The Raspberry Pi 5 version of the **main OpenMANET web portal** uses a color scheme broadly similar to the original OpenMANET portal.

However, the theme is inconsistent.

Several boxes, cards, or content containers on the **home page appear with white backgrounds**, despite the rest of the interface using the original dark color scheme.

This makes the Raspberry Pi 5 portal look unfinished and visually inconsistent with the original OpenMANET user interface.

### Important distinction

**This task concerns the main OpenMANET portal, NOT the application or interface hosted on port 8080.**

Do not modify the port 8080 application's frontend, styling, assets, or layout as part of this fix.

## Reference

Use the original OpenMANET portal from the working Raspberry Pi 3 release as the visual reference.

Reference firmware:

```text
OpenMANET 24.10 release 1.8.1
```

Compare its home page against the Raspberry Pi 5 portal.

The goal is for the Raspberry Pi 5 portal to conform to the same dark visual design, while preserving any intentional Pi 5-specific features.

## Required investigation

Inspect the main OpenMANET portal frontend and identify:

- Home-page components with white backgrounds.
- Hardcoded light CSS colors.
- Missing dark-mode styles.
- Incorrect CSS variables.
- Incorrect design-token mappings.
- Component-specific style overrides.
- Theme-provider configuration issues.
- Incorrect use of default component-library styling.
- Missing or outdated stylesheet imports.
- Differences between the Pi 3 and Pi 5 frontend builds.

Determine whether the white boxes are caused by regressions, missing styling, or newer components that were not updated for dark mode.

## Required implementation

1. Apply the original OpenMANET dark theme consistently to the Raspberry Pi 5 portal.
2. Replace unintended white card backgrounds with appropriate dark theme surfaces.
3. Use existing theme tokens or CSS variables wherever possible.
4. Avoid introducing inconsistent one-off colors.
5. Preserve existing page layouts.
6. Preserve status indicator meaning and colors.
7. Preserve navigation and functionality.
8. Ensure responsive styling works on desktop and mobile.
9. Keep text, borders, buttons, and interactive controls readable.
10. Prevent third-party component styles from overriding the intended dark theme.

Do not solve the problem by applying a global CSS rule that indiscriminately darkens maps, images, charts, modal content, or other components that intentionally require different colors.

## Visual expectations

The Raspberry Pi 5 portal should have:

- Consistent dark page backgrounds.
- Consistent dark card and panel backgrounds.
- Correct text contrast.
- Appropriate border colors.
- Harmonized shadows and highlights.
- Consistent button styling.
- Consistent status-indicator styling.
- Appropriate hover and focus states.
- No unintended white boxes on the home page.

The original OpenMANET dark portal is the visual target.

## Required visual tests

Compare the Pi 3 and Pi 5 portal home pages.

Capture before-and-after screenshots at:

- Desktop viewport.
- Tablet viewport.
- Mobile viewport.

Verify:

- Home-page cards.
- Status panels.
- Network information boxes.
- Mesh status panels.
- Device information sections.
- Navigation components.
- Header and footer.
- Buttons and dropdowns.
- Modals and interactive panels.

Confirm all affected components visually conform to the intended dark-theme design.

## Acceptance criteria

- No unintended white cards or home-page containers.
- Theme resembles the original OpenMANET dark appearance.
- Text and controls remain readable.
- Portal functionality is unchanged.
- Responsive layouts remain functional.
- No visual regressions in unrelated pages.
- Port 8080 application remains completely unchanged.
- Before-and-after screenshots included in release validation.

## Deliverables

Provide:

- Root-cause explanation.
- List of affected frontend components.
- List of modified CSS or component files.
- Styling fixes.
- Screenshots.
- Visual regression checks where feasible.

Include the theme fixes in the same Raspberry Pi 5 firmware release.

---

# 10. P1 — First-Boot Diagnostics and Self-Validation

Implement a reliable first-boot health-check process.

It should verify:

```text
SD card detected
Root partition identified
Root partition expanded
F2FS overlay expanded
Filesystem writable
Package repositories valid
BATMAN kernel module loaded
BATMAN protocol registered
bat0 created
BATMAN hard interface attached
bat0 bridged correctly
802.11s interface operational
Local AP operational
Ethernet uplink operational
Docker storage writable
Docker file capabilities supported
```

Report meaningful errors through system logs and the OpenMANET portal where appropriate.

Distinguish between:

1. BATMAN device exists.
2. BATMAN hard interface attached.
3. Wireless mesh peer established.
4. BATMAN neighbor detected.
5. BATMAN originator route learned.
6. Mesh gateway reachable.
7. Internet uplink available.

Do not report a fully operational mesh simply because the BATMAN interface is up.

First-boot checks must be safe, repeatable, and non-destructive.

---

# 11. P1 — Firmware Upgrade and Configuration Migration

These fixes must work on freshly flashed devices and existing installations.

## Requirements

Preserve:

- Mesh credentials.
- Wireless radio configuration.
- Mesh IDs.
- Management IP addresses.
- Gateway/mesh-point roles.
- WAN settings.
- DHCP and firewall configuration.
- OpenMANET settings.
- Docker volumes and container data.
- OpenTAKServer configuration.

Migrations must:

- Repair incomplete BATMAN configurations safely.
- Avoid duplicate network sections.
- Avoid duplicate bridge ports.
- Avoid unnecessary radio reconfiguration.
- Avoid destroying Docker data.
- Be idempotent.
- Support rollback when possible.

Never blindly replace `/etc/config/network` or `/etc/config/wireless` with a template from a different device.

Ensure upgrade behavior is tested independently from first-flash behavior.

---

# 12. Required Automated Tests

Add build-time and runtime checks wherever practical.

## Build-time tests

- Validate the generated package repository URLs.
- Validate package architecture compatibility.
- Validate kernel ABI alignment.
- Validate F2FS security-xattr configuration.
- Validate generated BATMAN UCI sections.
- Validate expected bridge membership.
- Validate wireless hard-interface binding.
- Validate presence of required packages.
- Validate portal theme assets and CSS.
- Confirm portal changes do not affect port 8080.

## Runtime tests

```bash
opkg update
df -h /overlay /opt/docker
ubus call network.interface.bat0 status
batctl meshif bat0 if
batctl meshif bat0 n
batctl meshif bat0 o
ls /sys/class/net/br-ahwlan/brif/
docker info
docker compose ps
```

Also verify:

- Docker layer extraction with security capability attributes.
- OpenTAKServer service accessibility.
- Persistent data after reboot.
- Two-node mesh forwarding.
- SD-card auto-expansion.
- LuCI BATMAN display.
- Main portal dark-theme consistency.

---

# 13. Release Priority Matrix

| Priority | Issue | Requirement |
|---|---|---|
| P0 | BATMAN configuration | Fix first-boot initialization |
| P0 | BATMAN topology | Correct wireless hard-interface and bridge binding |
| P0 | Package repositories | Replace broken feed configuration |
| P0 | Docker capabilities | Resolve `security.capability` failure |
| P0 | OpenTAKServer | Confirm complete deployment |
| P1 | SD-card expansion | Automatic F2FS growth |
| P1 | Mesh connectivity | Two-node peering and forwarding |
| P1 | First-boot diagnostics | Automated validation |
| P1 | Firmware migrations | Preserve existing user settings |
| P2 | Portal theme | Correct white home-page cards |
| P2 | Resource accounting | Audit Docker memory/swap support |

All of these issues should be addressed in the next planned release, even though their severity differs.

---

# 14. Required Deliverables

## A. Source-level fixes

Modify the actual firmware repository and build configuration.

Include:

- BATMAN UCI configuration generation.
- Wireless mesh binding.
- Bridge configuration.
- Gateway and mesh-point role handling.
- Package feed generation.
- Kernel filesystem security options.
- Docker storage configuration.
- SD-card expansion mechanism.
- First-boot health checks.
- Upgrade migration logic.
- Main OpenMANET portal dark-theme styling.

## B. Firmware image

Build a reproducible Raspberry Pi 5 firmware image using the project's established format.

Preserve hardware compatibility and existing OpenMANET functionality.

## C. Technical report

Document, for every issue:

- Observed problem.
- Root cause.
- Files modified.
- Implementation details.
- Validation performed.
- Test results.
- Remaining limitations.

Distinguish confirmed root causes from hypotheses.

## D. Regression tests

Include automated tests for configuration generation, package feeds, and kernel feature requirements.

Add UI regression coverage for the dark-theme issues.

## E. Upgrade and rollback guidance

Provide safe instructions for migrating existing Pi 5 installations without losing:

- Network configuration.
- Mesh credentials.
- Management access.
- Docker storage.
- OpenTAKServer data.

## F. Release notes

Summarize user-facing improvements, bug fixes, compatibility changes, and any required upgrade actions.

---

# 15. Constraints

The following requirements are mandatory:

1. Do not blindly copy Pi 3 hardware settings to Pi 5.
2. Do not hardcode physical wireless interface names.
3. Do not hardcode the F2FS offset.
4. Do not resize a mounted F2FS root using offline filesystem tools.
5. Do not mix incompatible OpenWrt package ABIs.
6. Do not install kernel modules built for a different kernel ABI.
7. Do not bridge the gateway WAN into the client mesh bridge.
8. Do not bypass BATMAN by bridging the 802.11s interface directly.
9. Do not overwrite user network credentials.
10. Do not destroy existing Docker volumes.
11. Do not change the port 8080 application's visual theme.
12. Do not claim Docker compatibility without successful image extraction.
13. Do not claim working multi-node mesh connectivity based only on a locally active `bat0`.
14. Do not declare the release complete without recording validation results.
15. Do not replace the existing OpenMANET storage architecture without a justified technical reason.

---

# 16. Definition of Done

The next Raspberry Pi 5 OpenMANET firmware release is complete only when:

- [ ] The firmware flashes and boots successfully.
- [ ] BATMAN-V initializes automatically.
- [ ] The correct wireless mesh hard interface attaches to `bat0`.
- [ ] `bat0` is correctly bridged into `br-ahwlan`.
- [ ] The upstream gateway interface remains correctly routed.
- [ ] LuCI displays BATMAN as a supported protocol.
- [ ] Two OpenMANET nodes successfully peer and exchange mesh traffic.
- [ ] `opkg update` succeeds with valid feeds.
- [ ] The writable F2FS overlay expands automatically.
- [ ] Docker supports Linux file-capability attributes.
- [ ] Docker images extract without `lsetxattr` errors.
- [ ] OpenTAKServer containers start successfully.
- [ ] OpenTAKServer is reachable through the intended mesh network.
- [ ] Docker and OpenTAKServer data survive reboot.
- [ ] The main Raspberry Pi 5 OpenMANET portal matches the original dark-theme design.
- [ ] No unintended white home-page cards remain.
- [ ] The application running on port 8080 remains unchanged.
- [ ] Existing configurations survive firmware upgrades.
- [ ] Automated validation and release notes are included.

---

# 17. Final Instructions to the Build Agent

Begin by inspecting the current Raspberry Pi 5 firmware repository, existing build configuration, network initialization scripts, Docker configuration, and web portal frontend.

Identify the exact source files responsible for each issue.

Implement fixes at their source rather than relying on post-boot manual workarounds.

Prioritize work in the following order:

1. **Docker/F2FS security capability support**, because this is the most significant confirmed remaining deployment blocker.
2. **BATMAN-V initialization and topology**, because these required manual corrections and must be fixed in the generated firmware.
3. **Package feed compatibility**, to restore reliable package management.
4. **Automatic SD-card/F2FS expansion**, to eliminate manual storage recovery.
5. **Multi-node mesh testing and OpenTAKServer integration**, to verify actual functionality.
6. **OpenMANET portal dark-theme fixes**, to restore visual consistency with the original implementation.
7. **First-boot diagnostics and upgrade safety**, to prevent regressions.

For every proposed change, determine the root cause, implement the source-level correction, and verify it with appropriate tests.

Commit changes with clear descriptions and provide the resulting firmware artifact or build instructions.

If physical Raspberry Pi 5 hardware is unavailable, complete all source-level, build-time, and automated checks that can be performed, then explicitly identify the remaining hardware validation steps.

**Final goal: Deliver a stable, reproducible Raspberry Pi 5 OpenMANET firmware release that provides reliable BATMAN mesh networking, functional package management, full SD-card utilization, Docker/OpenTAKServer compatibility, and a consistently dark OpenMANET portal matching the original design.**
