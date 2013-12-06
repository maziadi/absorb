# module pour l'installation du serveur Central-log
# le serveur utilise rsyslog avec la base de donnee MySQL

class rsyslog_1_0::common  inherits syslog-ng {
  case $rsyslog_ip_service {'': { $rsyslog_ip_service = '169.254.0.160' } }
  case $rsyslog_master {'': { $rsyslog_master = false } }
  case $rsyslog_slave {'': { $rsyslog_slave = false } }
  case $rsyslog_mainq {'': { $rsyslog_mainq = false } }
  case $rsyslog_send_to_server {'': { $rsyslog_send_to_server = true } }
  case $rsyslog_ubuntu {'': { $rsyslog_ubuntu = false } }
  case $rsyslog_zimbra {'': { $rsyslog_zimbra = false } }

  # Si true: listen en UDP (valable pour les clients uniquement)
  case $rsyslog_is_syslog_server {'': { $rsyslog_is_syslog_server = false } }

  Package["syslog-ng"]{
      ensure  => purged,
      before => undef
  }

  replace {
    no_dns_resolution_c4:
      file        => "/etc/default/rsyslog",
      pattern     => 'RSYSLOGD_OPTIONS="-c4"',
      replacement => 'RSYSLOGD_OPTIONS="-c4 -x"',
      notify      =>  Service["rsyslogd"];
    no_dns_resolution_c5:
      file        => "/etc/default/rsyslog",
      pattern     => 'RSYSLOGD_OPTIONS="-c5"',
      replacement => 'RSYSLOGD_OPTIONS="-c5 -x"',
      notify      =>  Service["rsyslogd"];
    no_dns_resolution:
      file        => "/etc/default/rsyslog",
      pattern     => 'RSYSLOGD_OPTIONS=""',
      replacement => 'RSYSLOGD_OPTIONS="-x"',
      notify      =>  Service["rsyslogd"];
    no_dns_resolution_suppressc5:
      file        => "/etc/default/rsyslog",
      pattern     => 'RSYSLOGD_OPTIONS="-c5 -x"',
      replacement => 'RSYSLOGD_OPTIONS="-x"',
      notify      =>  Service["rsyslogd"];
  }
  File["/etc/syslog-ng/syslog-ng.conf"] {
    ensure => absent,
    content => undef,
    require => undef
  }
  Service["syslog-ng"]{
    ensure => undef,
    enable => undef ,
    subscribe => undef,
    status => "/bin/false"
  }

  file {
    "/etc/rsyslog.conf":
      content => template("rsyslog_1_0/rsyslog-client.conf.erb"),
      owner   => root, group   => root, mode    => 644,
      require => Package["rsyslog"],
      before  => Service["rsyslogd"],
      notify  => Service["rsyslogd"];
    "/var/spool/rsyslog":
      ensure  => directory;
  }

  if $rsyslog_mainq {
    config_file {
      "/var/spool/rsyslog/mainq":
        ensure  => present,
        content => "",
        group   => "adm";
    }
  }

  package {
    "rsyslog":  
      ensure  => present;
  }
}

class rsyslog_1_0::rsyslog-client {
#alias rsyslog-client 
  service {
    "rsyslogd":
      name      => "rsyslog",
      enable    => true,
      ensure    => running;
  }
  include rsyslog_1_0::common
}

class rsyslog_1_0::rsyslog-server inherits rsyslog_1_0::common {
  case $rsyslog_group {'': { $rsyslog_group = true } }
  case $rsyslog_ip_replication { '': { $rsyslog_ip_replication = false } }

  File["/etc/rsyslog.conf"] {
    content => template("rsyslog_1_0/rsyslog-server.conf.erb"),
    require => Package["rsyslog"],
    notify  => Service["rsyslogd"]
  }
  if $rsyslog_ip_replication {
     file {
        "/etc/rsyslog.d/repli.conf":
          content => template("rsyslog_1_0/repli.conf.erb"),
          mode    => 644, owner => root, group => root,
          notify  =>  service["rsyslogd"],
          require => package["rsyslog"];
    }
  }

  file {
    "/var/log/syslog":
      ensure  => directory;
    "/var/log/old":
      ensure  => directory;
    "/var/log/old/syslog":
      ensure  => directory;
  }

  case $rsyslog_group {
    true: {
      file {
        "/etc/rsyslog.d/gen_group.conf":
          source  => "${files_root}/rsyslog_1_0/gen_group.conf",
          mode    => 644, owner => root, group => root,
          notify  =>  service["rsyslogd"],
          require => package["rsyslog"];
        "/etc/logrotate.d/rsyslog":
          source => "${files_root}/rsyslog_1_0/logrotate_rsyslog.conf",
          mode => 644, owner => root, group => root;
      }
    }
  }
}
