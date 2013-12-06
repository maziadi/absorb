class collectd_1_1::plugin::irq (
  $irqs           = 'UNSET',
  $ignoreselected = 'false',
  $ensure         = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'irq.conf':
    ensure    => $collectd_1_1::plugin::irq::ensure,
    path      => "${conf_dir}/irq.conf",
    mode      => '0644',
    owner     => 'root',
    group     => 'root',
    content   => template('collectd_1_1/irq.conf.erb'),
    notify    => Service['collectd']
  }
}
