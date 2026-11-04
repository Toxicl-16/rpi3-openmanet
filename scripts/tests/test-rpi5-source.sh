#!/bin/sh

set -eu

repo=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
board="$repo/boards/ekh-bcm2712/target_diffconfig"

assert_contains() {
	file="$1"
	needle="$2"
	grep -F "$needle" "$file" >/dev/null || {
		echo "FAIL: $file does not contain: $needle" >&2
		exit 1
	}
}

assert_contains "$board" 'CONFIG_PACKAGE_openmanet-node-fixes=y'
assert_contains "$board" 'CONFIG_PACKAGE_openmanetd=y'
assert_contains "$board" 'CONFIG_PACKAGE_opentakserver=y'
assert_contains "$board" '# CONFIG_TARGET_ROOTFS_EXT4FS is not set'
assert_contains "$board" 'CONFIG_TARGET_DEFAULT_LAN_IP_FROM_PREINIT=y'
assert_contains "$repo/target/linux/bcm27xx/base-files/etc/board.d/02_network" 'raspberrypi,5-model-b)'
assert_contains "$repo/target/linux/bcm27xx/base-files/lib/preinit/05_set_preinit_iface_brcm2708" 'raspberrypi,5-model-b |'
assert_contains "$repo/target/linux/bcm27xx/base-files/etc/board.d/02_network" 'ipaddr "10.41.254.1"'
assert_contains "$board" 'CONFIG_PACKAGE_batctl=y'
assert_contains "$board" 'CONFIG_PACKAGE_libcap-bin=y'
assert_contains "$board" 'CONFIG_PACKAGE_e2fsprogs=y'
assert_contains "$board" 'CONFIG_PACKAGE_resize2fs=y'
assert_contains "$board" 'CONFIG_KERNEL_CGROUPS=y'
assert_contains "$board" 'CONFIG_KERNEL_MEMCG=y'
assert_contains "$board" 'CONFIG_KERNEL_CGROUP_DEVICE=y'
assert_contains "$board" 'CONFIG_KERNEL_F2FS_FS_SECURITY=y'
assert_contains "$board" 'CONFIG_PACKAGE_kmod-brcmfmac=y'
assert_contains "$board" 'CONFIG_PACKAGE_cypress-firmware-43455-sdio=y'
assert_contains "$board" 'CONFIG_PACKAGE_brcmfmac-nvram-43455-sdio=y'
assert_contains "$board" 'CONFIG_PACKAGE_wpad-basic-mbedtls=y'
assert_contains "$repo/target/linux/bcm27xx/bcm2712/target.mk" 'ARCH_PACKAGES:=aarch64_cortex-a72'
assert_contains "$repo/include/feeds.mk" 'CONFIG_TARGET_bcm27xx_bcm2712'
assert_contains "$repo/target/linux/bcm27xx/image/cmdline.txt" 'rootfstype=squashfs,ext4'
assert_contains "$repo/package/openmanet-node-fixes/files/lib/preinit/79_openmanet_storage_expand" 'resize2fs'
assert_contains "$repo/package/openmanet-node-fixes/files/lib/preinit/79_openmanet_storage_expand" 'resize.f2fs'
assert_contains "$repo/feeds/morse/essentials/morse-fw/Makefile" 'mm8108b2-rl.bin'
assert_contains "$repo/package/firmware/linux-firmware/broadcom.mk" 'brcmfmac43455-sdio.raspberrypi,5-model-b.txt'
assert_contains "$repo/package/firmware/cypress-firmware/Makefile" 'brcmfmac43455-sdio.raspberrypi,5-model-b.bin'
assert_contains "$repo/package/kernel/mac80211/broadcom.mk" 'brcmfmac-bca.ko'
assert_contains "$repo/feeds/routing/batman-adv/Makefile" 'PKG_VERSION:=2023.1'
assert_contains "$repo/feeds/routing/batctl/Makefile" 'PKG_VERSION:=2023.1'
test ! -d "$repo/package/piaware" || {
	echo 'FAIL: PiAware package must not be part of the active source tree' >&2
	exit 1
}
for file in \
	"$repo/package/openmanet-node-fixes/files/usr/sbin/openmanet-batman" \
	"$repo/package/openmanet-node-fixes/files/usr/sbin/openmanet-health" \
	"$repo/package/openmanet-node-fixes/files/lib/preinit/79_openmanet_storage_expand" \
	"$repo/package/openmanet-node-fixes/files/etc/init.d/openmanet-batman" \
	"$repo/package/openmanet-node-fixes/files/etc/init.d/openmanet-health"; do
	sh -n "$file"
done

rootfs=$(find "$repo/staging_dir" -path '*/root-bcm27xx/etc/opkg/distfeeds.conf' -type f -print -quit 2>/dev/null || true)
if [ -n "$rootfs" ]; then
	grep -F '/packages/aarch64_cortex-a72/' "$rootfs" >/dev/null || {
		echo "FAIL: generated package feeds do not use aarch64_cortex-a72" >&2
		exit 1
	}
	if grep -Eq '/targets/bcm2712/|aarch64_cortex-a76' "$rootfs"; then
		echo 'FAIL: generated package feeds contain an unavailable Pi 5/a76 repository' >&2
		exit 1
	fi
fi

kernel_config=$(find "$repo/build_dir" -path '*/linux-bcm27xx_bcm2712/linux-6.6.133/.config' -type f -print -quit 2>/dev/null || true)
if [ -n "$kernel_config" ]; then
	for option in CONFIG_CGROUPS CONFIG_MEMCG CONFIG_F2FS_FS CONFIG_F2FS_FS_XATTR CONFIG_F2FS_FS_SECURITY CONFIG_SECURITY; do
		grep -E "^${option}=y$" "$kernel_config" >/dev/null || {
			echo "FAIL: generated kernel is missing $option" >&2
			exit 1
		}
	done
fi

echo 'PASS: Pi 5 firmware source checks'
