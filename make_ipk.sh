#!/bin/bash
set -e

# Default to 1.0.0 if PKG_VERSION is not passed in from environment
VERSION="${PKG_VERSION:-1.0.0}"
PKG_NAME="luci-app-radius4wifi"
PKG_VER="${VERSION}-1"

# Create build workspace directories
BUILD_DIR="/tmp/ipk_build"
CONTROL_DIR="${BUILD_DIR}/control"
DATA_DIR="${BUILD_DIR}/data"
IPK_DIR="${BUILD_DIR}/ipk"

rm -rf "${BUILD_DIR}"
mkdir -p "${CONTROL_DIR}" "${DATA_DIR}" "${IPK_DIR}"

# Inject dynamic VERSION into control file
cat << EOF > "${CONTROL_DIR}/control"
Package: ${PKG_NAME}
Version: ${PKG_VER}
Architecture: all
Maintainer: Lascaille
Depends: freeradius3, freeradius3-mod-eap, freeradius3-mod-eap-tls, luci-base, openssl-util
Section: luci
Category: LuCI
Title: LuCI support for RADIUS4WiFi
Description: Simple EAP-TLS RADIUS Provisioning for OpenWrt
EOF

cat << EOF > "${CONTROL_DIR}/conffiles"
/etc/config/radius4wifi
EOF

cp -r files/* "${DATA_DIR}/"

# Ensure scripts preserve execution permissions inside the package
chmod +x "${DATA_DIR}/etc/init.d/"* 2>/dev/null || true
chmod +x "${DATA_DIR}/etc/uci-defaults/"* 2>/dev/null || true

cd "${DATA_DIR}"
tar -czf "${IPK_DIR}/data.tar.gz" .

cat << 'EOF' > "${CONTROL_DIR}/postinst"
#!/bin/sh
[ -n "$IPKG_INSTROOT" ] || {
    grep -q "^radius4wifi:" /etc/group || echo "radius4wifi:x:200:" >> /etc/group
    grep -q "^radius4wifi:" /etc/passwd || echo "radius4wifi:x:200:200:radius4wifi daemon:/var/run/radius4wifi:/bin/false" >> /etc/passwd

    if [ -f /etc/uci-defaults/99_radius4wifi ]; then
        sh /etc/uci-defaults/99_radius4wifi && rm -f /etc/uci-defaults/99_radius4wifi
    fi
}
exit 0
EOF
chmod +x "${CONTROL_DIR}/postinst"

cd "${CONTROL_DIR}"
tar -czf "${IPK_DIR}/control.tar.gz" .

echo "2.0" > "${IPK_DIR}/debian-binary"

cd "${IPK_DIR}"
FINAL_IPK="${PKG_NAME}_${PKG_VER}_all.ipk"
tar -czf "${FINAL_IPK}" debian-binary control.tar.gz data.tar.gz

mv "${FINAL_IPK}" /tmp/
echo "Done! Package created at /tmp/${FINAL_IPK}"