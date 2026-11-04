#!/bin/sh
# Apply the Pi 5 SDK compatibility fixes after updating/installing feeds.
set -eu

cd "$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

apply_patch_once() {
    patch_file=$1
    if patch -p1 --forward --dry-run < "$patch_file" >/dev/null 2>&1; then
        patch -p1 --forward < "$patch_file"
    elif patch -p1 --reverse --dry-run < "$patch_file" >/dev/null 2>&1; then
        echo "Already applied: $patch_file"
    else
        echo "Cannot apply $patch_file; check feed revisions in feeds.conf.default." >&2
        exit 1
    fi
}

# Existing checkouts may still have the old feed recipe installed. Fresh
# feed installs automatically prefer the in-tree package/lang/rust recipe.
./scripts/feeds uninstall rust
apply_patch_once patches/build-fixes/002-morse-backports-version.patch
cp patches/build-fixes/003-morse-optional-spi-flag.patch \
    feeds/morse/essentials/morse_driver/patches/016-optional-spi-flag.patch
cp patches/build-fixes/004-morse-short-beacon-api.patch \
    feeds/morse/essentials/morse_driver/patches/017-short-beacon-api.patch
cp patches/build-fixes/005-morse-channel-ignore-fallback.patch \
    feeds/morse/essentials/morse_driver/patches/018-channel-ignore-fallback.patch
apply_patch_once patches/build-fixes/006-pi4-eeprom-dependency.patch
apply_patch_once patches/build-fixes/007-luci-iwinfo-buffer-compat.patch
apply_patch_once patches/build-fixes/008-luci-lemon-prototypes.patch
apply_patch_once patches/build-fixes/009-golang-host-gnu17.patch
cp patches/build-fixes/010-perl-sdbm-gcc15.patch \
    feeds/packages/lang/perl/patches/1000-gcc15-sdbm.patch
apply_patch_once patches/build-fixes/011-luci-runtime-lemon-prototypes.patch
apply_patch_once patches/build-fixes/012-bash-host-gnu17.patch
apply_patch_once patches/build-fixes/013-openmanet-home-dark-theme.patch
apply_patch_once patches/build-fixes/014-dockerd-f2fs-vfs-config.patch
# These unused prpl forks conflict with the 23.05 LuCI UPnP dependency graph.
# The Pi 5 image uses firewall4 and does not select either fork.
./scripts/feeds uninstall miniupnpd-prpl miniupnpd2
