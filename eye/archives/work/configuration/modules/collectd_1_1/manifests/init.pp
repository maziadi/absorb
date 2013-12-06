class collectd_1_1::collectd (
  $fqdnlookup   = true,
  $interval     = 60,
  $threads      = 5,
  $timeout      = 2,
) {

  include collectd_1_1::params

  exec {
    "collectd":
      command => "/usr/bin/apt-get install --no-install-recommends --yes collectd",
      unless => "/usr/bin/which collectd",
      before => File['/etc/collectd/collectd.conf'];
  }

  package {
    "libsnmp15":
      ensure => present;
    "libxml2":
      ensure => present;
  }

  file {
    "/etc/collectd":
      ensure  => directory,
      mode    => '0644',
      owner   => 'root',
      group   => 'root';
    "/etc/collectd/conf.d":
      ensure  => directory,
      mode    => '0644',
      owner   => 'root',
      require => File["/etc/collectd"],
      group   => 'root';
    "/etc/collectd/collectd.conf":
      content => template('collectd_1_1/collectd.conf.erb'),
      require => File["/etc/collectd"],
      notify  => Service['collectd'];
    "/etc/collectd/filters.conf":
      source => "${files_root}/collectd_1_1/filters.conf",
      require => File["/etc/collectd"],
      notify  => Service['collectd'];
    "/etc/collectd/types.db":
      content => template('collectd_1_1/collectd.types.db.erb'),
      require => File["/etc/collectd"];
  }

  service { 'collectd':
    ensure    => running,
    enable    => true,
    require   => Exec['collectd'],
  }

  class { 'collectd_1_1::plugin::disk': }
  class { 'collectd_1_1::plugin::interface': }
  class {
    'collectd_1_1::plugin::df':
      fstypes        => ["tmpfs","rootfs","udev"],
      ignoreselected => true,
      reportbydevice => true,
      reportinodes   => true;
    'collectd_1_1::plugin::syslog':
      log_level => 'info';
  }

}

class collectd_1_1::collectd-client (
  $server_addr,
  $server_port = 25826,
  $username,
  $password
) {
  class { 'collectd_1_1::collectd': }
  class {
    'collectd_1_1::plugin::network':
      server => $server_addr,
      serverport => $server_port,
      server_securitylevel => 'Encrypt',
      server_username => $username,
      server_password => $password,
      maxpacketsize => "1452",
      reportstats => true;
  }
}

class collectd_1_1::collectd-server (
  $listen_addr,
  $listen_port = 25826,
  $username,
  $password,
  $graphite_host = '127.0.0.1'
) {

  class { 'collectd_1_1::collectd': }
  class {
    'collectd_1_1::plugin::network':
      listen => $listen_addr,
      listenport => $listen_port,
      listen_securitylevel => 'Encrypt',
      listen_authfile => "/etc/collectd/passwd",
      maxpacketsize => "1452",
      reportstats => true;
    'collectd_1_1::plugin::write_graphite':
       graphitehost => $graphite_host,
       storerates   => true;
  }
  file {
    "/etc/collectd/passwd":
      content => template('collectd_1_1/collectd.passwd.erb'),
      require   => Exec['collectd'];
  }
}

import "*"
