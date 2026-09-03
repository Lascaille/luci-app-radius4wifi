Simple WPA2-Enterprise provisioning with OpenWRT when using a separate WIFI AP.

Detects an existing freeradius installation and doesn't alter it.

Provisions a dedicated freeradius instance (radius4wifi) on a separate port with separated config.

Provisions a dedicated root CA and PKI store.

Includes LUCI UI for configuration and certificate management.

Install the package, go to the config page, enter the IP of your AP(s).

Make note of the secret and the port because the APs will ask for them.

Go to your AP's web config page, select WPA2-Enterprise, enter the IP of the router, the port and the secret.

Make client certificates on the AP config page and install them on the relevant mobile devices.

Connect the mobile device to the ssid, select EAP-TLS, no username, for identity select the relevant certificate, trust the certificate if prompted and you're set.
