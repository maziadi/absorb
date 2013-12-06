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

  File["/etc/rsyslog.conf"] {
    content => template("rsyslog/rsyslog-server.conf.erb"),
    require => Package["rsyslog"],
    notify  => Service["rsyslogd"]
  }

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
    "/var/log/old":
      ensure  => directory;
    "/var/log/old/syslog":
      ensure  => directory;
    "/etc/heartbeat/resource.d/promote_master" :
      owner => root, group => root, mode => 755,
      source => "${files_root}/rsyslog/promote_master";
  }

  replace {
    service_client:
      file        => "/etc/rc.local",
      pattern     => "# By default this script does nothing.",
      replacement => "/usr/sbin/rsyslogd -c3 -x -f /opt/local/etc/rsyslog.conf",
      require     => Package ["rsyslog"];
    no_dns_resolution:
      file        => "/etc/default/rsyslog",
      pattern     => 'RSYSLOGD_OPTIONS="-c3"',
      replacement => 'RSYSLOGD_OPTIONS="-c3 -x"',
      notify      =>  Service["rsyslogd"];
  }

  service {
    "rsyslogd":
      name      => "rsyslog",
      enable    => false;
  }
}  
