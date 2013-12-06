#modules rubyrep_1_0

class rubyrep_1_0::rubyrep {
  include mysql_1_0::mysql
  include monit

  case $rubyrep_mysql_first_bind_addr {
    '': {
      fail("rubyrep_mysql_first_bind_addr is required !")
    }
  }

  case $rubyrep_mysql_second_bind_addr {
    '': {
      fail("rubyrep_mysql_second_bind_addr is required !")
    }
  }

  case $rubyrep_mysql_database {
    '': {
      fail("rubyrep_mysql_database is required !")
    }
  }

  case $rubyrep_mysql_password {
    '': {
      fail("rubyrep_mysql_password is required !")
    }
  }

  case $rubyrep_mysql_replication_tables {
    '': {
      fail("rubyrep_mysql_replication_tables is required !")
    }
  }

  package {
	"libactiverecord-ruby1.8":
	  ensure => absent;
    "libmysql-ruby":
      ensure => present;
    "rubygems":
      ensure => present;
    "librubyrep-ruby":
      ensure => present,
      require => [Package["libmysql-ruby"],Package["rubygems"]];
  }

  file {
    "/etc/rubyrep":
      owner => root, group => root, mode => 750,
      ensure => directory;
    "/etc/rubyrep/initialize_location.sql":
      owner => root, group => root, mode => 750,
      source => "${files_root}/rubyrep_1_0/initialize_location.sql",
      require => File["/etc/rubyrep/rubyrep.conf"];
    "/etc/rubyrep/rubyrep.conf":
      owner => root, group => root, mode => 640,
      content => template("rubyrep_1_0/rubyrep.conf.erb"),
      require => [Package["librubyrep-ruby"],File["/etc/rubyrep"]],
      before => Service["rubyrep"];
    "/etc/init.d/rubyrep":
      owner => root, group => root, mode => 755,
      source => "${files_root}/rubyrep_1_0/etc/init.d/rubyrep",
      before => Service["rubyrep"];
  }

  $monit_conf_alert_email = $monit::monit_conf_alert_email

  file {
  "/etc/monitrc.d/rubyrep":
    owner => root, group => root, mode => 700, 
    content => template("monit/rubyrep.erb"),
    notify => Service["monit"],
    require => [Package["monit"], Package["librubyrep-ruby"]]
  }



  service {
    "rubyrep":
      enable => true,
      ensure  => running,
      hasrestart => true,
      pattern => '/rubyrep',
      subscribe => File["/etc/rubyrep/rubyrep.conf"];
  }

  #  GRANT SUPER ON *.* TO 'replication'@'%' IDENTIFIED BY PASSWORD '*DE6346340735D910F30BD2E603BF028339D00C78'
  #  GRANT ALL PRIVILEGES ON `opensips`.* TO 'replication'@'%'
  mysql_1_0::mysql::mysql_user {
    "replication":
  	  db => $rubyrep_mysql_database,
  	  password => $rubyrep_mysql_password,
      bypass => true;
  } 

  mysql_1_0::mysql::mysql_global_grant {
	"replication":
	  privileges => 'SUPER'
  }

}

class rubyrep_1_0::rubyrep_slave {
  include mysql_1_0::mysql

  file {
    "/etc/rubyrep":
      owner => root, group => root, mode => 750,
      ensure => directory;
    "/root/initialize_location.sql":
      owner => root, group => root, mode => 750,
      source => "${files_root}/rubyrep_1_0/initialize_location.sql";
  }
  case $rubyrep_mysql_database {
    '': {
      fail("rubyrep_mysql_database is required !")
    }
  }

  case $rubyrep_mysql_password {
    '': {
      fail("rubyrep_mysql_password is required !")
    }
  }

  #  GRANT SUPER ON *.* TO 'replication'@'%' IDENTIFIED BY PASSWORD '*DE6346340735D910F30BD2E603BF028339D00C78'
  #  GRANT ALL PRIVILEGES ON `opensips`.* TO 'replication'@'%'
  mysql_1_0::mysql::mysql_user {
    "replication":
  	  db => $rubyrep_mysql_database,
  	  password => $rubyrep_mysql_password,
      bypass => true;
  } 

  mysql_1_0::mysql::mysql_global_grant {
	"replication":
	  privileges => 'SUPER'
  }

}
