class collectd_1_1::plugin::bind (
  $url,
  $parsetime = 'false',
  $opcodes = 'true',
  $qtypes = 'true',
  $serverstats = 'true',
  $zonemaintstats = 'true',
  $resolverstats = 'false',
  $memorystats = 'true',
  $views = [],
  $ensure = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'bind.conf':
    ensure  => $collectd_1_1::plugin::bind::ensure,
    path    => "${conf_dir}/bind.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('collectd_1_1/bind.conf.erb'),
    notify  => Service['collectd']
  }
}
