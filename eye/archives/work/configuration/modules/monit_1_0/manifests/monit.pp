#
#
# Deploiment de Monit
#
# Variables: 
#   $ssmtp_mta
#   $monit_other_partition
#   $monit_load_five_min 
#   $monit_load_one_min 
#   $monit_cpu_usage 
#   $monit_memory_usage
#   $monit_conf_alert_email
#   $monit_space_usage
#   $monit_conf_alert_email
#

class monit_1_0::monit ( 
  $ssmtp_mta = $conf_mail_server,
  $monit_other_partition = [],
  $monit_load_five_min = 5,
  $monit_load_one_min = 10,
  $monit_cpu_usage = true,
  $monit_memory_usage = 75,
  $monit_space_usage = 80, 
  $monit_conf_alert_email = "monit@${email_domain_name}"

) { 

   package { "monit": 
       ensure => present, before => Service["monit"]
   }
    file {
        "/etc/monit/monitrc":
            owner => root,
            group => root,
            mode => 700,
            content => template("monit_1_0/monitrc.erb"),
            ensure => file,
            notify => Service["monit"],
            require => Package["monit"]
    }
    file { 
        "/etc/monit/conf.d":
            owner => root,
            group => root,
            mode => 700,
            ensure => directory,
            require => Package["monit"]
    }
# empty file (monit requires at least a file in an include dir)
    file {
        "/etc/monit/conf.d/000-empty-placeholder":
            owner => root,
            group => root,
            mode => 700,
            content => "", 
            ensure => file,
            require => File["/etc/monit/conf.d"]
    }
    replace { 
        "enable_monit":
            file => "/etc/default/monit",
            pattern => ".*startup=0.*",
            replacement => "startup=1",
            require => Package["monit"];
        "monit_interval":
            file => "/etc/default/monit",
            pattern => ".*CHECK_INTERVALS.*",
            replacement => "CHECK_INTERVALS=30",
            require => Package["monit"];
    }

    service { 
        "monit":
            enable => true,
            ensure => running,
            hasstatus => false,
            hasrestart => true,
            pattern => 'usr/sbin/monit';
    }
  
    define monit_file ($filename = $name , $requires = []) {
        $monit_conf_alert_email = $monit_1_0::monit::monit_conf_alert_email 
        file {
            "/etc/monit/conf.d/${filename}":
            owner => root, group => root, mode => 700, 
            content => template("monit_1_0/${name}.erb"),
            notify => Service["monit"],
            require => [Package["monit"], $requires ];
        }         
    }         
}
