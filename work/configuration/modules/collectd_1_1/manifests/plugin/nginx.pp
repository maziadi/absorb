class collectd_1_1::plugin::nginx (
  $url,
  $user = undef,
  $password = undef,
  $verifypeer = undef,
  $verifyhost = undef,
  $cacert = undef,
  $ensure = present
) {
  include collectd_1_1::params

  $conf_dir = $collectd_1_1::params::plugin_conf_dir

  file { 'nginx.conf':
    ensure  => $collectd_1_1::plugin::nginx::ensure,
    path    => "${conf_dir}/nginx.conf",
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('collectd_1_1/nginx.conf.erb'),
    notify  => Service['collectd']
  }
}
