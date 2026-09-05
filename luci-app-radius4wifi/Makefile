include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-radius4wifi
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-radius4wifi
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for Radius4WiFi
  DEPENDS:=+radius4wifi +luci-base +openssl-util
  PKGARCH:=all
endef

define Package/luci-app-radius4wifi/description
  LuCI interface and certificate management tools for Radius4WiFi.
endef

define Build/Compile
	# Plain payload, no binary compilation required
endef

define Package/luci-app-radius4wifi/install
	# Helper script (executable)
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/radius4wifi-cert $(1)/usr/sbin/radius4wifi-cert

	# RPCD ACL definition
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-radius4wifi.json $(1)/usr/share/rpcd/acl.d/luci-app-radius4wifi.json

	# LuCI Menu JSON routing
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-radius4wifi.json $(1)/usr/share/luci/menu.d/luci-app-radius4wifi.json

	# LuCI JavaScript view
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/radius4wifi
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/radius4wifi/overview.js $(1)/www/luci-static/resources/view/radius4wifi/overview.js
endef

$(eval $(call BuildPackage,luci-app-radius4wifi))
