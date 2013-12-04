class collectd_1_1::plugin::interface (
  $interfaces     = ["lo"],
  $ignoreselected = 'true',
  $ensure         = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'interface.conf':
    ensure    => $collectd_1_1::plugin::interface::ensure,
    path      => "${conf_dir}/interface.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/interface.conf.erb'),
    notify    => Service['collectd']
  }
}
