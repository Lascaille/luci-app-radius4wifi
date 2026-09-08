include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-radius4wifi
PKG_VERSION:=1.0.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-radius4wifi
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI support and isolated FreeRADIUS service for Wi-Fi
	DEPENDS:=+freeradius3 +freeradius3-mod-eap +freeradius3-mod-eap-tls +openssl-util +luci-base
	PKGARCH:=all
endef

define Package/luci-app-radius4wifi/description
	Unified LuCI management interface, cert helper tool, and isolated FreeRADIUS setup.
endef

define Build/Compile
	# Pure script payload, no compilation required
endef

define Package/luci-app-radius4wifi/conffiles
	/etc/radius4wifi/
	/etc/config/radius4wifi
endef

define Package/luci-app-radius4wifi/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/radius4wifi $(1)/etc/config/radius4wifi

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/radius4wifi $(1)/etc/init.d/radius4wifi

	$(INSTALL_DIR) $(1)/etc/radius4wifi
	$(CP) ./files/etc/radius4wifi/* $(1)/etc/radius4wifi/

	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/usr/sbin/radius4wifi-cert $(1)/usr/sbin/radius4wifi-cert

	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-radius4wifi.json $(1)/usr/share/rpcd/acl.d/luci-app-radius4wifi.json

	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/usr/share/luci/menu.d/luci-app-radius4wifi.json $(1)/usr/share/luci/menu.d/luci-app-radius4wifi.json

	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/radius4wifi
	$(INSTALL_DATA) ./files/www/luci-static/resources/view/radius4wifi/overview.js $(1)/www/luci-static/resources/view/radius4wifi/overview.js
endef

$(eval $(call BuildPackage,luci-app-radius4wifi))