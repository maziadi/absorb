class collectd_1_1::plugin::disk (
  $disks          = [],
  $ignoreselected = 'false',
  $ensure         = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'disk.conf':
    ensure    => $collectd_1_1::plugin::disk::ensure,
    path      => "${conf_dir}/disk.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/disk.conf.erb'),
    notify    => Service['collectd']
  }

}
