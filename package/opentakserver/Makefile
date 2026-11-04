include $(TOPDIR)/rules.mk

PKG_NAME:=opentakserver
PKG_RELEASE:=1
PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=OpenMANET / Build with Parallel integration

# Optional build-time bundle. When absent, Docker Compose pulls the ARM64
# images on the node's first start.
OTS_BUNDLE_PATH ?= $(TOPDIR)/firmware-output/ots/opentakserver-arm64-images.tar.zst

include $(INCLUDE_DIR)/package.mk

define Package/opentakserver
  SECTION:=net
  CATEGORY:=Network
  TITLE:=OpenTAKServer Docker deployment
  DEPENDS:=+dockerd +docker-compose +ca-bundle +curl
  PKGARCH:=all
endef

define Package/opentakserver/description
  OpenTAKServer Docker Compose deployment and an OpenWrt procd service.
  The service uses persistent storage under /opt/opentakserver.
endef

define Package/opentakserver/conffiles
/etc/config/opentakserver
/opt/opentakserver/compose.yaml
/opt/opentakserver/ots_config.env
endef

define Build/Compile
endef

define Package/opentakserver/install
	$(INSTALL_DIR) $(1)/etc/config $(1)/etc/init.d $(1)/usr/sbin $(1)/opt/opentakserver
	$(INSTALL_CONF) ./files/opentakserver.config $(1)/etc/config/opentakserver
	$(INSTALL_BIN) ./files/opentakserver.init $(1)/etc/init.d/opentakserver
	$(INSTALL_BIN) ./files/opentakserver-setup $(1)/usr/sbin/opentakserver-setup
	$(INSTALL_CONF) ./files/compose.yaml $(1)/opt/opentakserver/compose.yaml
	$(INSTALL_CONF) ./files/ots_config.env $(1)/opt/opentakserver/ots_config.env
	$(INSTALL_DATA) ./files/README.OpenTAKServer $(1)/opt/opentakserver/README.OpenTAKServer
	if [ -f "$(OTS_BUNDLE_PATH)" ]; then \
		$(INSTALL_DATA) "$(OTS_BUNDLE_PATH)" $(1)/opt/opentakserver/offline-images.tar.zst; \
	fi
endef

$(eval $(call BuildPackage,opentakserver))
