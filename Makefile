include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-radius4wifi
PKG_VERSION:=1.0.4
PKG_RELEASE:=1

PKG_MAINTAINER:=Community
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-radius4wifi
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Minimal EAP-TLS RADIUS Server & Cert Manager
  DEPENDS:=+freeradius3 +freeradius3-mod-eap +freeradius3-mod-eap-tls +luci-base +openssl-util
  USERID:=radius4wifi=200:radius4wifi=200
  PKGARCH:=all
endef

define Package/luci-app-radius4wifi/description
  Lightweight EAP-TLS authentication stack running FreeRADIUS under an unprivileged user.
endef

define Build/Compile
endef

define Package/luci-app-radius4wifi/install
	$(INSTALL_DIR) $(1)/
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,luci-app-radius4wifi))
