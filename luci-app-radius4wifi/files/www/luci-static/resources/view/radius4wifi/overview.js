'use strict';
'require view';
'require form';
'require fs';
'require ui';

return view.extend({
load: function() {
  return fs.list('/etc/radius4wifi/certs').then(function(entries) {
    var matches = (entries || []).filter(function(e) {
      return e.name && e.name.endsWith('.p12');
    });

    var tasks = [];
    var certNames = [];

    matches.forEach(function(m) {
      var name = m.name.replace(/\.p12$/, '');
      certNames.push(name);
      tasks.push(fs.read('/etc/radius4wifi/certs/' + name + '.pass').catch(function() { return 'N/A'; }));
    });

    return Promise.all(tasks).then(function(passwords) {
      var certs = [];
      for (var i = 0; i < certNames.length; i++) {
        certs.push({
          name: certNames[i],
          pass: (passwords[i] || 'N/A').trim()
        });
      }
      return certs;
    });
  }).catch(function() { return []; });
},

  render: function(certs) {
    var m, s, o;

    m = new form.Map('radius4wifi', _('Radius4WiFi Configuration'),
      _('Configure isolated EAP-TLS settings for your Access Points and manage client certificates.'));

    // Server Section
    s = m.section(form.TypedSection, 'server', _('RADIUS Server Settings'));
    s.anonymous = true;

    o = s.option(form.Value, 'port', _('Listening Port'));
    o.datatype = 'port';
    o.default = '18120';
    o.rmempty = false;

    o = s.option(form.DynamicList, 'client_net', _('Access Point IP Addresses'),
      _('IP addresses of your Access Points allowed to authenticate with this RADIUS server.'));
    o.datatype = 'ip4addr';
    o.default = '192.168.1.2';
    o.rmempty = false;

    o = s.option(form.Value, 'secret', _('Shared Secret'));
    o.password = true;
    o.rmempty = false;
    
    // ------------------------------------------------------------------
    // CA Certificate Download Section
    // ------------------------------------------------------------------
    s = m.section(form.NamedSection, 'main', 'radius4wifi', _('Certificate Authority (CA)'),
      _('Download the Root CA certificate to manually trust the RADIUS server on Windows and legacy devices.'));

    var dlCaBtn = s.option(form.Button, '_download_ca', _('CA Certificate'));
    dlCaBtn.inputtitle = _('Download CA (.crt)');
    dlCaBtn.inputstyle = 'action';
    dlCaBtn.onclick = function() {
      return fs.read('/etc/radius4wifi/pki/ca.pem').then(function(content) {
        var blob = new Blob([content], { type: 'application/x-x509-ca-cert' });
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = 'Radius4WiFi-CA.crt';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }).catch(function(err) {
        ui.addNotification(null, E('p', _('Error reading CA certificate: ') + (err.message || err)), 'error');
      });
    };

    // Certificate Generator Section
    s = m.section(form.NamedSection, '_cert_gen', 'cert_gen', _('Generate Client Certificate'),
      _('Generate a .p12 identity bundle for a client device.'));

    var certNameOpt = s.option(form.Value, '_cert_name', _('Device Label'),
      _('Letters and numbers only (e.g. "johnphone"). Formatted as r4w-YYYYMMDD-label.'));
    certNameOpt.rmempty = true;

    var genBtn = s.option(form.Button, '_generate', _('Generate Certificate'));
    genBtn.inputtitle = _('Generate Certificate');
    genBtn.inputstyle = 'apply';
    genBtn.onclick = function() {
      // Canonical LuCI method to retrieve an option value from a named section
      var val = (certNameOpt.formvalue('_cert_gen') || '').trim();

      // Fallback to name attribute lookup if formvalue returns empty
      if (!val) {
        var inputEl = document.querySelector('input[name="' + certNameOpt.cbid('_cert_gen') + '"]');
        val = inputEl ? inputEl.value.trim() : '';
      }

      if (!val || !val.match(/^[a-zA-Z0-9_-]+$/)) {
        ui.addNotification(null, E('p', _('Invalid Device Label. Use only letters, numbers, hyphens, and underscores.')), 'error');
        return;
      }

      ui.showModal(_('Generating Certificate'), [
        E('p', { 'class': 'spinning' }, _('Generating EC key pair and PKCS#12 bundle...'))
      ]);

      return fs.exec('/usr/sbin/radius4wifi-cert', ['generate', val]).then(function(res) {
        ui.hideModal();
        if (res.code === 0) {
          ui.addNotification(null, E('p', _('Certificate generated successfully!')), 'info');
          location.reload();
        } else {
          ui.addNotification(null, E('p', _('Error generating certificate.')), 'error');
        }
      });
    };
    


    // Issued Certificates Table
    s = m.section(form.TableSection, '_certs', _('Issued Certificates'));
    s.anonymous = true;
    s.nodescriptions = true;

    s.cfgsections = function() {
      return certs.map(function(c) { return c.name; });
    };

    o = s.option(form.DummyValue, 'name', _('Cert CN'));
    o.cfgvalue = function(section_id) { return section_id; };

    o = s.option(form.DummyValue, 'pass', _('Password'));
    o.cfgvalue = function(section_id) {
      var match = certs.find(function(c) { return c.name === section_id; });
      return match ? match.pass : 'N/A';
    };

    var dlBtn = s.option(form.Button, '_download', _('Download'));
    dlBtn.inputtitle = _('Download .p12');
    dlBtn.inputstyle = 'action';
    dlBtn.onclick = function(ev, section_id) {
      return fs.read('/etc/radius4wifi/certs/' + section_id + '.p12').then(function(content) {
        var blob = new Blob([content], { type: 'application/x-pkcs12' });
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = section_id + '.p12';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      });
    };

    var delBtn = s.option(form.Button, '_delete', _('Delete'));
    delBtn.inputtitle = _('Delete');
    delBtn.inputstyle = 'remove';
    delBtn.onclick = function(ev, section_id) {
      if (!confirm(_('Are you sure you want to delete certificate "%s"?').format(section_id))) {
        return;
      }
      return fs.exec('/usr/sbin/radius4wifi-cert', ['delete', section_id]).then(function(res) {
        if (res.code === 0) {
          ui.addNotification(null, E('p', _('Certificate deleted successfully.')), 'info');
          location.reload();
        } else {
          ui.addNotification(null, E('p', _('Failed to delete certificate.')), 'error');
        }
      });
    };

    // Reset PKI Section
    s = m.section(form.NamedSection, '_pki_reset', 'pki_reset', _('Reset PKI Infrastructure'),
      _('WARNING: Resetting the PKI will permanently delete the Certificate Authority (CA), server keys, and ALL issued client certificates. All connected devices will immediately lose Wi-Fi access and must be re-provisioned with newly generated certificates.'));

    var chk1 = s.option(form.Flag, '_chk_confirm1', _('Acknowledge Revocation'),
      _('I understand that all existing client certificates will be deleted and invalidated immediately.'));
    chk1.rmempty = false;
    chk1.default = '0';

    var chk2 = s.option(form.Flag, '_chk_confirm2', _('Acknowledge Re-enrollment'),
      _('I really understand that this action is irreversible and requires re-configuring every client device.'));
    chk2.rmempty = false;
    chk2.default = '0';

    var resetBtn = s.option(form.Button, '_do_reset', _('Reset PKI'));
    resetBtn.inputtitle = _('Wipe & Reset PKI');
    resetBtn.inputstyle = 'remove';
    resetBtn.onclick = function() {
      // Use LuCI formvalue for section '_pki_reset'
      var is1Checked = chk1.formvalue('_pki_reset') === '1';
      var is2Checked = chk2.formvalue('_pki_reset') === '1';

      // Fallback DOM check using explicit section string '_pki_reset'
      if (!is1Checked || !is2Checked) {
        var el1 = document.getElementById(chk1.cbid('_pki_reset'));
        var el2 = document.getElementById(chk2.cbid('_pki_reset'));
        is1Checked = el1 && el1.checked;
        is2Checked = el2 && el2.checked;
      }

      if (!is1Checked || !is2Checked) {
        ui.addNotification(null, E('p', _('You must check BOTH confirmation boxes to enable PKI reset.')), 'error');
        return;
      }

      if (!confirm(_('FINAL WARNING: This will destroy all existing certificates and keys. Do you wish to continue?'))) {
        return;
      }

      ui.showModal(_('Resetting PKI'), [
        E('p', { 'class': 'spinning' }, _('Wiping PKI directory, destroying client certificates, and re-initializing CA...'))
      ]);

      return fs.exec('/usr/sbin/radius4wifi-cert', ['reset']).then(function(res) {
        if (res.code === 0) {
          return fs.exec('/etc/init.d/radius4wifi', ['restart']);
        } else {
          return Promise.reject(new Error(_('Reset script returned exit code ') + res.code));
        }
      }).then(function() {
        ui.hideModal();
        ui.addNotification(null, E('p', _('PKI infrastructure reset and service restarted successfully.')), 'info');
        location.reload();
      }).catch(function(err) {
        ui.hideModal();
        ui.addNotification(null, E('p', _('Error resetting PKI: ') + (err.message || err)), 'error');
      });
    };

    return m.render();
  }
});