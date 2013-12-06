#define ast_cfg() {
#  file {
#    "/etc/asterisk/${name}":
#        owner => asterisk, group => asterisk, mode => 664,
#        content => template("centrex/asterisk/${name}.erb"),
#        require => Package["asterisk"],
#        before => Service["asterisk"];
#  }
#}

class centrex::server_2_0 {
  include system::sun-jdk6
  include mysql
  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  mysql_db {
    "centrex":
      username => 'asterisk_cdr',
      password => $centrex_cdr_password;
  }

  package {
    [   
      "centrex",
      "asterisk",
      "asterisk-mysql"
    ] :
      ensure => present;
  }
  file {
      "/etc/monitrc.d/centrex":
        owner => root, group => root, mode => 700,
        content => template("centrex/centrex-monitrc.d.erb"),
        notify => Service[monit],
        ensure => present;
  }
  service {
    "centrex":
      ensure => running,
      enable => true,
      require => Package["centrex"];
  }

  file {
    "/etc/cron.daily/clean-centrex.sh":
      owner => root, group => root, mode => 755,
      content => "find /var/lib/centrex/ -name 'model.bin_*' -ctime +30 -exec rm -f {} \\;",
      ensure => present;
    "/etc/cron.daily/centrex-logs":
      owner => root, group => root, mode => 755,
      content => template("centrex/centrex-logs.erb"),
      ensure => present;
  }
}
