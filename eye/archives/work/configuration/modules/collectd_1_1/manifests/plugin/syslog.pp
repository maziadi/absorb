class collectd_1_1::plugin::syslog (
  $ensure    = present,
  $log_level = 'info'
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'syslog.conf':
    ensure    => $collectd_1_1::plugin::syslog::ensure,
    path      => "${conf_dir}/syslog.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/syslog.conf.erb'),
    notify    => Service['collectd'],
  }
}
