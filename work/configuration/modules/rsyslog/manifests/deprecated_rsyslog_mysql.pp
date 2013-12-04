# module pour l'installation du serveur Central-log
# le serveur utilise rsyslog avec la base de donnee MySQL

class rsyslog::rsyslog inherits syslog-ng {
  case $rsyslog_ip_service {'': { $rsyslog_ip_service = '169.254.0.160' } }
  case $rsyslog_master {'': { $rsyslog_master = false } }
  case $rsyslog_slave {'': { $rsyslog_slave = false } }

  Package["syslog-ng"] {
    ensure  => absent
  }
  File["/etc/syslog-ng/syslog-ng.conf"] {
    ensure => absent
  }
  Service["syslog-ng"] {
    enable => false,
    ensure => undef
  }

  file {
    "/etc/rsyslog.conf":
      content => template("rsyslog/rsyslog-client.conf.erb"),
      owner   => root, group   => root, mode    => 644,
      require => Package["rsyslog"],
      before  => Service["rsyslogd"],
      notify  => Service["rsyslogd"];
    "/var/spool/rsyslog":
      ensure  => directory;
  }

  config_file {
    "/var/spool/rsyslog/mainq":
      ensure  => present,
      content => "",
      group   => "adm";
  }

  package {
    "rsyslog":  
      ensure  => present;
  }
}

class rsyslog::rsyslog-client inherits rsyslog::rsyslog {
#alias rsyslog-client 
  service {
    "rsyslogd":
      name      => "rsyslog",
      enable    => true,
      ensure    => running;
  }

}

class rsyslog::rsyslog-server inherits rsyslog::rsyslog {

#  $rsyslog_mysql_dbuser   = "rsyslog"
#  $rsyslog_mysql_password = "Z6hnhg0WA9C4"
#  $rsyslog_mysql_dbname   = "SYSLOG"
#  $mysql_expire_logs_days = "1"
#
#  system::debian::debconf_set_selections {
#    "rsyslog-mysql rsyslog-mysql/dbconfig-install boolean true": 
#      package => "rsyslog-mysql";
#  }
#
  File["/etc/rsyslog.conf"] {
    content => template("rsyslog/rsyslog-server.conf.erb"),
    require => Package["rsyslog"],
    notify  => Service["rsyslogd"]
  }

#  config_file {
#    "/etc/rsyslog.d/mysql.conf":
#      content => template("rsyslog/mysql.conf.erb"),
#      ensure  => present,
#      require => Package["rsyslog-mysql"],
#      notify  => Service["rsyslogd"];
#
#    "/etc/dbconfig-common/rsyslog-mysql.conf":
#      content => template("rsyslog/rsyslog-mysql.conf.erb"),
#      mode    => 600,
#      ensure  => present,
#      before  => Package["rsyslog-mysql"];
#
#    "/opt/local/share/create-tables.sql":
#      content => template("rsyslog/create-tables.sql.erb"),
#      ensure  => present,
#      before  => Package["mysql-server"];
#    "/opt/local/bin/rsyslog-archive.rb":
#      mode    => 755,
#      content => template("rsyslog/rsyslog-archive.rb.erb"),
#      ensure  => present;
#  }

#  cron {
#    "rsyslog_archive":
#      command => "/opt/local/bin/rsyslog-archive.rb archive-day && /opt/local/bin/rsyslog-archive.rb clean --day 10",
#      user => root,
#      minute => '30',
#      hour => '0';
#  }

  file {
    "/etc/logrotate.d/rsyslog":
      source => "${files_root}/rsyslog/logrotate_rsyslog.conf",
      mode => 644, owner => root, group => root;
    "/opt/local/bin/initialize_iscsi.sh":
      source => "${files_root}/rsyslog/initialize_iscsi.sh",
      mode => 700, owner => root, group => root;
    # fichier pour lancer un rsyslog client sur le serveur
    "/opt/local/etc/rsyslog.conf":
      content => template("rsyslog/rsyslog-client.conf.erb"),
      owner   => root, group   => root, mode    => 644,
      require => Package["rsyslog"];
#    "/etc/dbconfig-common":
#      require => Package["dbconfig-common"],
#      ensure  => directory;
    "/var/log/old":
      ensure  => directory;
    "/var/log/old/syslog":
      ensure  => directory;
#    "/var/log/old/sql":
#      ensure  => directory;
    }

  replace {
    service_client:
      file => "/etc/rc.local",
      pattern => "# By default this script does nothing.",
      replacement => "/opt/local/bin/promote_slave\n/usr/sbin/rsyslogd -c3 -x -f /opt/local/etc/rsyslog.conf",
      require => Package ["rsyslog"];
  }

#  package {
#    "rsyslog-mysql": 
#      before  => Exec["Set MySQL server root password"],
#      ensure  => present,
#      require => [
#          File["/etc/dbconfig-common/rsyslog-mysql.conf"],
#          Package["rsyslog"],
#          Package["mysql-server"]
#        ];
#     "dbconfig-common":
#       before => Package["rsyslog-mysql"],
#       ensure => present;
#     "libmysql-ruby1.8":
#       ensure  => present;
#     "libcmdparse2-ruby1.8":
#       ensure  => present;
#     "maatkit":
#       ensure  => present;
#  }

  service {
    "rsyslogd":
      name      => "rsyslog",
      enable    => false;
  }

#  if $rsyslog_slave {
#    mysql_1_0::mysql-repli::mysql_setup_slave_db {
#      "${rsyslog_mysql_dbname}":
#        username  => $rsyslog_mysql_dbuser,
#        password  => $rsyslog_mysql_password,
#        require => Package["rsyslog-mysql"]
#    }
#    
#  } else {
#   mysql_1_0::mysql::mysql_db {
#      "${rsyslog_mysql_dbname}":
#        username  => $rsyslog_mysql_dbuser,
#        password  => $rsyslog_mysql_password,
#        init_file => "/opt/local/share/create-tables.sql",
#        require => Package["rsyslog-mysql"]
#    }
#  }
#  
#  mysql_1_0::mysql-repli::mysql_repli_user {
#    "grant privileges to ${mysql_repli_user}":
#      db => $rsyslog_mysql_dbname,
#      mysql_repli_user => "rep_slave",
#      mysql_repli_pass => "Eipha8si",
#      require => Exec["create mysql db ${rsyslog_mysql_dbname}"]
#  }
#
#  include mysql_1_0::mysql-repli

}  
