class collectd_1_1::plugin::iptables (
  $chains = 'UNSET',
  $ensure = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'iptables.conf':
    ensure    => $collectd_1_1::plugin::iptables::ensure,
    path      => "${conf_dir}/iptables.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/iptables.conf.erb'),
    notify    => Service['collectd']
  }
}
