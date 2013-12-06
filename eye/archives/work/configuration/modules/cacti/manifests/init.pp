class cacti::cacti {
  include mysql_1_0::mysql

  system_1_0::debian::debconf_set_selections {
    "cacti cacti/dbconfig-install boolean true": package => "cacti"
  }
  config_file {
    "/etc/dbconfig-common/cacti.conf" :
      content => template("cacti/cacti-dbconfig.conf.erb"),
      mode => 600,
      before => Package["cacti"];
  }
  file {
    "/etc/dbconfig-common":
      ensure => directory;
    "/etc/apache2/conf.d/cacti":
      ensure => "/etc/cacti/apache.conf",
      require => Package["apache2"],
      notify => Service["apache2"];
  }
  package {
  "cacti":
    before  => Exec["Set MySQL server root password"],
    ensure  => present,
    require => [File["/etc/dbconfig-common/cacti.conf"],Package["mysql-server"]];
  "apache2": ensure => present;
  "dbconfig-common":
    before => Package["cacti"],
    ensure => present;
  }

  service {
    "apache2":
      ensure => running;
  }
}

