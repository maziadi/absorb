class collectd_1_1::plugin::jmx (
  $jmx_service_url,
  $jmx_host,
  $jmx_user,
  $jmx_password,
  $jmx_collects = [],
  $ensure   = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'jmx.conf':
    ensure  => $collectd_1_1::plugin::jmx::ensure,
    path    => "${conf_dir}/jmx.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('collectd_1_1/jmx.conf.erb'),
    notify  => Service['collectd'],
  }
}
