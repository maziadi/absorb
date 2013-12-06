class collectd_1_1::plugin::write_graphite (
  $graphitehost = 'localhost',
  $storerates   = false,
  $graphiteport = '2003',
  $ensure       = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'write_graphite.conf':
    ensure    => $collectd_1_1::plugin::write_graphite::ensure,
    path      => "${conf_dir}/write_graphite.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/write_graphite.conf.erb'),
    notify    => Service['collectd'],
  }
}
