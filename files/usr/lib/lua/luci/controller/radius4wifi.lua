module("luci.controller.radius4wifi", package.seeall)

function index()
    entry({"admin", "services", "radius4wifi"}, cbi("radius4wifi"), _("Radius4WiFi"), 60)
    entry({"admin", "services", "radius4wifi", "download"}, call("action_download")).leaf = true
    entry({"admin", "services", "radius4wifi", "delete"}, call("action_delete")).leaf = true
end

function action_download(cert_name)
    local fs = require "nixio.fs"
    if not cert_name or not cert_name:match("^[a-zA-Z0-9_-]+$") then
        luci.http.status(400, "Bad Request")
        return
    end

    local path = "/etc/radius4wifi/certs/" .. cert_name .. ".p12"
    if fs.access(path) then
        local content = fs.readfile(path)
        luci.http.header('Content-Disposition', 'attachment; filename="' .. cert_name .. '.p12"')
        luci.http.prepare_content("application/x-pkcs12")
        luci.http.write(content)
    else
        luci.http.status(404, "Not Found")
    end
end

function action_delete(cert_name)
    local fs = require "nixio.fs"
    if not cert_name or not cert_name:match("^[a-zA-Z0-9_-]+$") then
        luci.http.status(400, "Bad Request")
        return
    end

    -- Remove all generated certificate artifacts
    fs.remove("/etc/radius4wifi/certs/" .. cert_name .. ".p12")
    fs.remove("/etc/radius4wifi/certs/" .. cert_name .. ".pass")
    fs.remove("/etc/radius4wifi/certs/pki/" .. cert_name .. ".key")
    fs.remove("/etc/radius4wifi/certs/pki/" .. cert_name .. ".crt")
    fs.remove("/etc/radius4wifi/certs/pki/" .. cert_name .. ".csr")

    luci.http.redirect(luci.dispatcher.build_url("admin/services/radius4wifi"))
end