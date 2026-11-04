include $(TOPDIR)/rules.mk

PKG_NAME:=openmanet-node-fixes
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=OpenMANET / Build with Parallel integration

include $(INCLUDE_DIR)/package.mk

define Package/openmanet-node-fixes
  SECTION:=net
  CATEGORY:=Network
  TITLE:=OpenMANET Pi 5 boot migrations and diagnostics
  DEPENDS:=+parted +partx-utils +losetup +blkid +f2fsck +e2fsprogs +resize2fs +libcap-bin +batctl
  PKGARCH:=all
endef

define Package/openmanet-node-fixes/description
Pi 5-only source-level migrations for SD-card growth, BATMAN-V topology
repair, and first-boot health diagnostics. Migrations are idempotent and
never replace the user's UCI configuration.
endef

define Build/Compile
endef

define Package/openmanet-node-fixes/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/etc/rc.d
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/lib/preinit
	$(INSTALL_CONF) ./files/etc/config/openmanet-node-fixes $(1)/etc/config/openmanet-node-fixes
	$(INSTALL_BIN) ./files/etc/init.d/openmanet-batman $(1)/etc/init.d/openmanet-batman
	$(INSTALL_BIN) ./files/etc/init.d/openmanet-health $(1)/etc/init.d/openmanet-health
	$(INSTALL_BIN) ./files/usr/sbin/openmanet-batman $(1)/usr/sbin/openmanet-batman
	$(INSTALL_BIN) ./files/usr/sbin/openmanet-health $(1)/usr/sbin/openmanet-health
	$(INSTALL_BIN) ./files/lib/preinit/79_openmanet_storage_expand $(1)/lib/preinit/79_openmanet_storage_expand
	$(LN) ../init.d/openmanet-batman $(1)/etc/rc.d/S12openmanet-batman
	$(LN) ../init.d/openmanet-health $(1)/etc/rc.d/S98openmanet-health
endef

$(eval $(call BuildPackage,openmanet-node-fixes))
