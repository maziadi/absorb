class collectd_1_1::plugin::postgresql (
  $database = '',
  $host     = 'UNSET',
  $username = 'UNSET',
  $password = 'UNSET',
  $port     = '3306',
  $query    = [],
  $ensure   = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'postgresql.conf':
    ensure  => $collectd_1_1::plugin::postgresql::ensure,
    path    => "${conf_dir}/postgresql.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('collectd_1_1/postgresql.conf.erb'),
    notify  => Service['collectd'],
  }
}
