class collectd_1_1::plugin::snmp (
  $hosts,
  $version = "1",
  $interval = "300",
  $ensure = present
) {
  include collectd_1_1::params
  $collect_snmp_groups = $collectd_1_1::params::collect_snmp_groups

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'snmp.conf':
    ensure  => $collectd_1_1::plugin::snmp::ensure,
    path    => "${conf_dir}/snmp.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('collectd_1_1/snmp.conf.erb'),
    notify  => Service['collectd']
  }
}
