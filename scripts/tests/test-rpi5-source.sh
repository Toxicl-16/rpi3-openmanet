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
assert_contains "$board" 'CONFIG_PACKAGE_opentakserver=y'
assert_contains "$board" '# CONFIG_TARGET_ROOTFS_EXT4FS is not set'
if grep -F 'CONFIG_TARGET_DEFAULT_LAN_IP_FROM_PREINIT=y' "$board" >/dev/null; then
	echo 'FAIL: Pi 5 must not generate a duplicate late LAN-IP board script' >&2
	exit 1
fi
assert_contains "$repo/target/linux/bcm27xx/base-files/etc/board.d/02_network" 'raspberrypi,5-model-b)'
assert_contains "$repo/target/linux/bcm27xx/base-files/lib/preinit/05_set_preinit_iface_brcm2708" 'raspberrypi,5-model-b |'
assert_contains "$repo/target/linux/bcm27xx/base-files/etc/board.d/02_network" 'ipaddr "10.41.254.1"'
assert_contains "$board" 'CONFIG_PACKAGE_batctl-default=y'
assert_contains "$board" 'CONFIG_PACKAGE_libcap-bin=y'
assert_contains "$board" 'CONFIG_KERNEL_MEMCG=y'
assert_contains "$board" 'CONFIG_KERNEL_CGROUP_DEVICE=y'
assert_contains "$board" 'CONFIG_KERNEL_F2FS_FS_SECURITY=y'
assert_contains "$repo/target/linux/bcm27xx/bcm2712/target.mk" 'ARCH_PACKAGES:=aarch64_cortex-a72'
assert_contains "$repo/include/feeds.mk" 'CONFIG_TARGET_bcm27xx_bcm2712'
assert_contains "$repo/target/linux/bcm27xx/image/cmdline.txt" 'rootfstype=squashfs,f2fs'
assert_contains "$repo/target/linux/bcm27xx/patches-6.6/999-001-openmanet-enable-pi5-docker-memory-cgroups.patch" 'cgroup_disable=memory'
assert_contains "$repo/package/opentakserver/Makefile" '+docker-compose'
assert_contains "$repo/feeds/openmanet/routing/batman-adv/Makefile" 'PKG_VERSION:=2025.4'
assert_contains "$repo/feeds/openmanet/routing/batctl/Makefile" 'PKG_VERSION:=2025.4'
assert_contains "$repo/patches/build-fixes/013-openmanet-home-dark-theme.patch" 'feeds/morse/luci/luci-mod-home'
assert_contains "$repo/patches/build-fixes/014-dockerd-f2fs-vfs-config.patch" 'option storage_driver '\''vfs'\'''
test ! -d "$repo/package/piaware" || {
	echo 'FAIL: PiAware package must not be part of the active source tree' >&2
	exit 1
}
if rg -n '8080' "$repo/package/opentakserver" >/dev/null; then
	echo 'FAIL: OpenTAKServer must not claim port 8080' >&2
	exit 1
fi

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
