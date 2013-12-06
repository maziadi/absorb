class openfire_1_0::openfire_1_0 {
  include system::sun-jdk6
  
  $openfire_mysql_dbuser   = "openfire"
  $openfire_mysql_password = "Z6hnhTGFJR98"
  $openfire_mysql_dbname   = "openfire"

  config_file {
   "/tmp/openfire_mysql.sql":
     content => template("openfire_1_0/openfire_mysql.sql"),
     ensure  => present,
     before  => Package["mysql-server"];
  }
  replace {
    "/etc/default/openfire":
      file => "/etc/default/openfire",
      pattern => "DAEMON_OPTS=\"\"",
      replacement => "DAEMON_OPTS=\"-Xmx400m\"",
      notify => Service["openfire"];
  }
  service {
    "openfire":
      enable => true,
      ensure => running;
  }
  mysql_1_0::mysql::mysql_db {
    "${openfire_mysql_dbname}":
      username  => $openfire_mysql_dbuser,
      password  => $openfire_mysql_password,
      init_file => "/tmp/openfire_mysql.sql"
  }
  include mysql_1_0::mysql
}
