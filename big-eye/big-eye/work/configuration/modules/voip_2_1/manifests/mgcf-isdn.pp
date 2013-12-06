#
# Classe pour une passerelle ISDN VOIP
#
# Inclut: 
# Paramètres:
#
# Implemented for asterisk 1.6

class voip_2_1::mgcf-isdn(
  $active_mq_agent_password,
  $sigal_inbound_gw_channel_names,
  $sigal_outbound_gw_channel_names,
  $sigal_log_level = "INFO",
  $isdn_session_timeout = '14400',
  $sigal_maximum_pool_size = '250',
  $sip_timer_t1 = 500,
  $asterisk_t1min = 100,
  $sip_probing = 'no'
  ) {
  $snmp_asterisk = true

  class {
    "voip_2_1::sigal-isdn-agent":
      active_mq_agent_password => $active_mq_agent_password,
      sigal_inbound_gw_channel_names => $sigal_inbound_gw_channel_names,
      sigal_outbound_gw_channel_names => $sigal_outbound_gw_channel_names,
      sigal_log_level => $sigal_log_level,
      sigal_maximum_pool_size => $sigal_maximum_pool_size;
  } 

  define cfg_file($recurse = false, $notify = [], content = '', mode = 644) {
    case $content {
      default: {
        file {
          "${name}":
            owner => root, group => root, mode => $mode,
            content => $content,
            notify => $notify, 
            require => Package["asterisk"],
            before => Service["asterisk"],
            recurse => $recurse;
        }
      }
      '' : {
        file {
          "${name}":
            owner => root, group => root, mode => $mode,
            source => [
              "${dist_files}/nodes/${hostname}/${name}",
              "${files_root}/voip_2_1/mgcf-isdn/${name}"
            ],
            notify => $notify, 
            require => Package["asterisk"],
            before => Service["asterisk"],
            recurse => $recurse;
        }
      }
    }
  }

  package {
    [
      "asterisk",
      "dahdi",
      "dahdi-source",
      "asterisk-dahdi",
      "libpri-dev",
      "build-essential",
      "g++",
      "libncurses5-dev",
      "bison",
      "flex",
      "psmisc",
      "automake",
      "autoconf",
      "linux-headers-2.6-amd64",
      "libtool"
    ] : ensure => present;
  }
  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  file {
    "/etc/wanpipe/scripts/start":
      ensure => absent;
    "/etc/monitrc.d/asterisk":
      owner => root, group => root, mode => 700,
      content => template("monit/asterisk_1.8.8.erb"),
      notify => Service["monit"],
      require => [Package["monit"]];
   "/opt/local/bin/jmxterm-downloader":
      owner => root, group => root, mode => 755,
      source => "${files_root}/voip_2_1/routag/opt/local/bin/jmxterm-downloader",
      before => Exec["jmxterm-downloader"];
  }

  service {
    "asterisk":
      ensure => running,
      pattern => "/asterisk$",
      enable => true,
      hasrestart => true;
  }

  file {
    "/opt/local/bin/chankiller":
      owner => root, group => root, mode => 755,
      content => template("voip_2_1/mgcf-isdn/chankiller.erb");
  }

   cfg_file {
    "/etc/wanpipe/":
      mode => 755,
      recurse => true;
    "/etc/dahdi/system.conf": ;
    "/usr/src/lsb_wanrouter.patch": ;
    "/usr/src/patch_wanrouter.sh":
      mode => 755;
    "/etc/asterisk/ccss.conf": ;
    "/etc/asterisk/chan_dahdi.conf":
      notify => Exec["reload_asterisk_dahdi"];
    "/etc/asterisk/extensions.conf":
      notify => Exec["reload_asterisk_extensions"]; 
    "/etc/asterisk/features.conf": ;
    "/etc/asterisk/indications.conf": ;
    "/etc/asterisk/logger.conf":
      notify => Exec["reload_asterisk_logger"];
    "/etc/asterisk/manager.conf": ;
    "/etc/asterisk/modules.conf": ;
    "/etc/asterisk/sip.conf":
      content => template("voip_2_1/mgcf-isdn/sip.conf.erb"),
      notify => Exec["reload_asterisk_sip"];
    "/opt/local/bin/restartwhenconvenient":
      mode => 755;
    "/opt/local/bin/mib_asterisk":
      mode => 755;
    "/opt/local/bin/detect_errors.sh":
      content => template("voip_2_1/mgcf-isdn/detect_errors.sh.erb"),
      mode => 755;
    "/opt/local/bin/check-isdn-call-setup.sh":
      mode => 755;
    "/opt/local/bin/sangoma_report.sh":
      mode => 755;
    "/opt/local/bin/dahdi_dnd.sh":
      mode => 755;
    "/root/screenrc":
      mode => 644;
  }
  exec { "reload_asterisk_dahdi":
    command => "/usr/sbin/asterisk -n -rx 'dahdi reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "reload_asterisk_extensions":
    command => "/usr/sbin/asterisk -n -rx 'dialplan reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "reload_asterisk_logger":
    command => "/usr/sbin/asterisk -n -rx 'logger reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "reload_asterisk_sip":
    command => "/usr/sbin/asterisk -n -rx 'sip reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "restart_asterisk_when_convenient":
    command => "/usr/sbin/asterisk -n -rx 'restart when convenient'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "jmxterm-downloader":
    cwd   => "/root",
    command => "/opt/local/bin/jmxterm-downloader",
    unless   => "test -f /root/jmxterm-1.0-alpha-4-uber.jar",
    timeout => 3600;
  }
  cron {
    "chankiller":
      command => "/opt/local/bin/chankiller",
      user => root,
      minute => '*/15';

    "detect_errors":
      command => "/opt/local/bin/detect_errors.sh",
      user    => root,
      minute  => '*/5',
      ensure  => present;
  }
}
