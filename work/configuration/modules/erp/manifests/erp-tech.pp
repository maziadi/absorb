class erp::erp-tech {
  case $erptech_directory     {'': { $erptech_directory = "/usr/share/erp-tech/" } }
  case $erptech_host      {'': { $erptech_host = "169.254.17.7" } }
  case $erptech_port      {'': { $erptech_port = "8000" } }
  case $erptech_mongrel_servers {'': { $erptech_mongrel_servers = "6" } }
  case $erptech_prefix      {'': { $erptech_prefix = "/erp-tech" } }

  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  package {
    [
      "nsis",
      "erp-tech",
      "irb",
      "mongrel",
      "mytop",
      "mongrel-cluster",
      "libmysql-ruby1.8",
      "rake",
      "curl",
      "subversion"
    ]: ensure => present;
  }
  
  config_file {
    "/etc/mongrel-cluster/sites-enabled/erp-tech-init.yml":
      content => template('erp/erp-tech-init.yml.erb'),
      require => Package["mongrel-cluster"],
      before => Service["mongrel-cluster"];
  }

  file {
    "/etc/monitrc.d/delayed_job":
      owner => root, group => root, mode => 700,
      content => template('erp/monit_delayed_job.erb'),
      notify => Service["monit"],
      require => [Package["monit"],Package["erp-tech"]];
  }
  file {
    "/data/pdaau":
      owner => www-data, group => www-data, mode => 700,
      ensure => directory;
  }

  service {
    "mongrel-cluster":
      enable => true,
      ensure => running,
      hasrestart => true,
      pattern => '/mongrel_rails';
  }
}
