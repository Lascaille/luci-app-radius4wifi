Simple WPA2-Enterprise provisioning with OpenWRT when using a separate WIFI AP.

Detects an existing freeradius installation and doesn't alter it.

Configures a custom freeradius instance (radius4wifi) on a custom port with separate config.

Configures a custom certificate directory and initialises PKI certs.

Includes LUCI UI to make/delete/revoke certificates and enter the WIFI AP IP (range) etc.

Install the package, go to the config page, enter the IP of your AP. Copy the secret and the port.
Go to the AP config page and confgiure WPA2-Enterprise and enter the IP of the router, the port and the secret.
Make client certificates on the AP config page and install them on the relevant mobile devices.
That's basically it.
