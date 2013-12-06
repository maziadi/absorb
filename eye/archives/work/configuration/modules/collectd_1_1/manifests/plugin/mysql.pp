class collectd_1_1::plugin::mysql (
  $database = 'UNSET',
  $host     = 'UNSET',
  $username = 'UNSET',
  $password = 'UNSET',
  $port     = '3306',
  $ensure   = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'mysql.conf':
    ensure  => $collectd_1_1::plugin::mysql::ensure,
    path    => "${conf_dir}/mysql.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('collectd_1_1/mysql.conf.erb'),
    notify  => Service['collectd'],
  }
}
