include $(TOPDIR)/rules.mk

PKG_NAME:=radius4wifi
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/radius4wifi
  SECTION:=net
  CATEGORY:=Network
  TITLE:=Isolated FreeRADIUS Instance for Wi-Fi
  DEPENDS:=+freeradius3 \
           +freeradius3-mod-eap \
           +freeradius3-mod-eap-tls \
           +freeradius3-mod-files \
           +openssl-util
  PKGARCH:=all
endef

define Package/radius4wifi/description
  Custom isolated FreeRADIUS payload and init service for Wi-Fi authentication.
endef

define Build/Compile
	# Static payload, no compilation required
endef

define Package/radius4wifi/conffiles
/etc/radius4wifi/
endef

define Package/radius4wifi/install
	# Install init.d service script
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/radius4wifi $(1)/etc/init.d/radius4wifi

	# Install /etc/radius4wifi config tree
	$(INSTALL_DIR) $(1)/etc/radius4wifi
	$(CP) ./files/etc/radius4wifi/* $(1)/etc/radius4wifi/
endef

$(eval $(call BuildPackage,radius4wifi))
