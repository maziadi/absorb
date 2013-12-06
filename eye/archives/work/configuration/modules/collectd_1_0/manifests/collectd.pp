class collectd_1_0::collectd (
$client = true,
$username = "",
$password = "",
$server_addr = "",
$server_port = "25826",
$net_interface = "",
$modules = [],
$greylist_module = ""
){
  case $lsbdistcodename {
    "wheezy": {
      package {
        "libssl1.0.0": ensure => present;
      }
    }
    "squeeze": {
      package {
        "libssl0.9.8" : ensure => present;
      }
    }
  } ->
  exec {
    "collectd":
      command => "/usr/bin/apt-get install --no-install-recommends --yes collectd",
      unless => "/usr/bin/which collectd";
  } ->
  package {
    "libsnmp15":
      ensure => present;
    "libxml2":
      ensure => present;
  } ->
  config_file {
    "/etc/collectd/collectd.conf" :
      #notify => Service["collectd"],
      content => template('collectd_1_0/collectd.conf.erb');
    "/etc/collectd/types.db":
      content => template('collectd_1_0/collectd.types.db.erb');
    "/etc/collectd/passwd":
      content => template('collectd_1_0/collectd.passwd.erb');
      #require => Package["collectd"],
      #before => Service["collectd"];
  } ~>
  service {
    "collectd":
      #require => Package["collectd"],
      enable  => true,
      ensure  => running;
  }

}
