local sys = require "luci.sys"
local nixio = require "nixio"
local fs = require "nixio.fs"

local function gen_pass()
    local chars = "abcdefghijklmnopqrstuvwxyz"
    local p = ""
    math.randomseed(os.time())
    for i = 1, 8 do
        local r = math.random(1, #chars)
        p = p .. chars:sub(r, r)
    end
    return p
end

local m, s, p, ip, sec, s2, cname, gen, s3, cn_col, pass_col, dl_col, del_col

m = Map("radius4wifi", "Radius4WiFi Configuration",
    "Configure isolated EAP-TLS settings for your Access Points and manage client certificates.")

s = m:section(TypedSection, "server", "RADIUS Server Settings")
s.anonymous = true

p = s:option(Value, "port", "Listening Port")
p.datatype = "port"
p.default = "18120"
p.rmempty = false

ip = s:option(DynamicList, "client_net", "Access Point IP Addresses", 
    "IP addresses of your Access Points allowed to authenticate with this RADIUS server.")
ip.datatype = "ip4addr"
ip.default = "192.168.1.2"
ip.rmempty = false

sec = s:option(Value, "secret", "Shared Secret")
sec.password = true
sec.rmempty = false

s2 = m:section(TypedSection, "server", "Generate Client Certificate",
    "Generate a .p12 identity bundle for a client device.")
s2.anonymous = true

cname = s2:option(Value, "_cert_name", "Device Label", 
    "Letters and numbers only (e.g. 'johnphone'). Formatted as r4w-YYYYMMDD-label.")
cname.rmempty = true
cname.cfgvalue = function(self, section)
    return ""
end

gen = s2:option(Button, "_generate", "Generate Certificate")
gen.inputtitle = "Generate Certificate"
gen.write = function(self, section)
    local raw_name = cname:formvalue(section)

    if raw_name and raw_name ~= "" and raw_name:match("^[a-zA-Z0-9_-]+$") then
        local date_str = os.date("%Y%m%d")
        local full_cn = string.format("r4w-%s-%s", date_str, raw_name)
        local pass = gen_pass()
        local pki = "/etc/radius4wifi/certs/pki"
        local out = "/etc/radius4wifi/certs"

        if not fs.access(pki .. "/ca.crt") then
            sys.call("/etc/init.d/radius4wifi start >/dev/null 2>&1")
        end

        local cmd = string.format(
            "openssl ecparam -name prime256v1 -genkey -out '%s/%s.key' && " ..
            "openssl req -new -key '%s/%s.key' -out '%s/%s.csr' -subj '/CN=%s' -nodes && " ..
            "openssl x509 -req -in '%s/%s.csr' -CA '%s/ca.crt' -CAkey '%s/ca.key' -CAcreateserial -out '%s/%s.crt' -days 3650 && " ..
            "openssl pkcs12 -export -out '%s/%s.p12' -inkey '%s/%s.key' -in '%s/%s.crt' -certfile '%s/ca.crt' -passout 'pass:%s' && " ..
            "printf '%%s' '%s' > '%s/%s.pass' && " ..
            "chown radius4wifi:radius4wifi '%s/%s.p12' '%s/%s.pass'",
            pki, full_cn,
            pki, full_cn, pki, full_cn, full_cn,
            pki, full_cn, pki, pki, pki, full_cn,
            out, full_cn, pki, full_cn, pki, full_cn, pki, pass,
            pass, out, full_cn,
            out, full_cn, out, full_cn
        )
        
        local res = sys.call(cmd)
        if res == 0 then
            m.message = string.format("Certificate '%s' generated successfully!", full_cn)
            luci.http.redirect(luci.dispatcher.build_url("admin/services/radius4wifi"))
        else
            m.message = "Error generating certificate. Check router system logs."
        end
    else
        m.message = "Invalid Device Label. Use only letters, numbers, hyphens, and underscores."
    end
end

local certs = {}
local fd = io.popen("ls /etc/radius4wifi/certs/*.p12 2>/dev/null")
if fd then
    for f in fd:lines() do
        local n = f:match("([^/]+)%.p12$")
        if n then table.insert(certs, n) end
    end
    fd:close()
end

if #certs > 0 then
    s3 = m:section(Table, certs, "Issued Certificates")
    s3.anonymous = true
    
    cn_col = s3:option(DummyValue, "name", "certCN")
    cn_col.cfgvalue = function(self, section)
        return certs[section]
    end

    pass_col = s3:option(DummyValue, "pass", "password")
    pass_col.cfgvalue = function(self, section)
        local name = certs[section]
        local pfile = "/etc/radius4wifi/certs/" .. name .. ".pass"
        if fs.access(pfile) then
            return fs.readfile(pfile) or "N/A"
        end
        return "N/A"
    end
    
    dl_col = s3:option(Button, "_download", "download")
    dl_col.inputtitle = "Download .p12"
    dl_col.write = function(self, section)
        local name = certs[section]
        luci.http.redirect(luci.dispatcher.build_url("admin/services/radius4wifi/download", name))
    end

    del_col = s3:option(Button, "_delete", "delete")
    del_col.inputtitle = "Delete"
    del_col.write = function(self, section)
        local name = certs[section]
        if name and name:match("^[a-zA-Z0-9_-]+$") then
            fs.remove("/etc/radius4wifi/certs/" .. name .. ".p12")
            fs.remove("/etc/radius4wifi/certs/" .. name .. ".pass")
            fs.remove("/etc/radius4wifi/certs/pki/" .. name .. ".key")
            fs.remove("/etc/radius4wifi/certs/pki/" .. name .. ".crt")
            fs.remove("/etc/radius4wifi/certs/pki/" .. name .. ".csr")
            
            m.message = string.format("Certificate '%s' deleted successfully.", name)
            luci.http.redirect(luci.dispatcher.build_url("admin/services/radius4wifi"))
        end
    end
end

return m
