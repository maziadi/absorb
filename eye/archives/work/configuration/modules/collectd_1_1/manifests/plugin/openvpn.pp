class collectd_1_1::plugin::openvpn (
  $statusfile             = '/etc/openvpn/openvpn-status.log',
  $improvednamingschema   = 'false',
  $collectcompression     = 'true',
  $collectindividualusers = 'true',
  $collectusercount       = 'false',
  $ensure                 = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'openvpn.conf':
    ensure    => $collectd_1_1::plugin::openvpn::ensure,
    path      => "${conf_dir}/openvpn.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/openvpn.conf.erb'),
    notify    => Service['collectd'],
  }
}
