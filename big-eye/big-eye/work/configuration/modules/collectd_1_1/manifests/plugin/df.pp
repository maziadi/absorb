class collectd_1_1::plugin::df (
  $mountpoints    = [],
  $fstypes        = [],
  $ignoreselected = 'false',
  $reportbydevice = 'false',
  $reportinodes   = 'true',
  $ensure         = present,
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'df.conf':
    ensure    => $collectd_1_1::plugin::df::ensure,
    path      => "${conf_dir}/df.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/df.conf.erb'),
    notify    => Service['collectd'],
  }
}
