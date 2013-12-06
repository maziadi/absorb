#
# Classe pour une passerelle ISDN VOIP
#
# ATTENTION: la grosse part de l'installation est faite a la main
# Inclut:
# Paramètres:
#
class voip_2_1::mgcf-ss7(
  $active_mq_agent_password,
  $sigal_inbound_gw_channel_names,
  $ss7_id,
  $ss7_switch_location,
  $sigal_log_level = "INFO",
  $ss7_session_timeout = '14400',
  $sigal_maximum_pool_size = '250',
  $ss7_provider_channel_name = 'g2',
  $ss7_own_channel_name = 'g1',
  $sip_timer_t1 = 500,
  $asterisk_t1min = 100,
  $sip_probing = 'no',
  $asterisk_file_descriptors = 4096,
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) {
  $snmp_asterisk = true

  class {
    "voip_2_1::sigal-ss7-agent":
      active_mq_agent_password => $active_mq_agent_password,
      sigal_inbound_gw_channel_names => $sigal_inbound_gw_channel_names,
      sigal_log_level => $sigal_log_level,
      sigal_maximum_pool_size => $sigal_maximum_pool_size,
      ss7_provider_channel_name => $ss7_provider_channel_name,
      ss7_own_channel_name => $ss7_own_channel_name,
      log_max_file_size => $log_max_file_size,
      log_max_index => $log_max_index;
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
              "${files_root}/voip_2_1/mgcf-ss7/${name}"
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
      "build-essential",
      "g++",
      "libncurses5-dev",
      "bison",
      "flex",
      "psmisc",
      "linux-headers-2.6-amd64",
      "libtool",
      "autoconf"
    ] : ensure => present;
  }
  replace {
    "enable_asterisk":
      file => "/etc/default/asterisk",
           pattern => ".*RUNASTERISK=no.*",
           replacement => "RUNASTERISK=yes",
           require => Package["asterisk"],
           before => Service["asterisk"];
  }

  service {
    "asterisk":
      enable => false,
      hasstatus => true,
      hasrestart => true;
  }

  file {
    "/opt/local/bin/chankiller":
      owner => root, group => root, mode => 755,
      content => template("voip_2_1/mgcf-ss7/chankiller.erb");
  }

  cfg_file {
    "/usr/src/lsb_wanrouter.patch":;
    "/usr/src/patch_wanrouter.sh":
      mode => 755;
    "/opt/local/bin/nsg_save.sh":
      mode => 755;
    "/etc/asterisk/sip.conf":
      content => template("voip_2_1/mgcf-ss7/${ss7_id}/sip.conf.erb"),
      notify =>  Exec["reload_asterisk_sip"];
    "/etc/asterisk/extensions.conf":
      content => template("voip_2_1/mgcf-ss7/${ss7_id}/extensions.conf.erb"),
      notify => Exec["reload_asterisk_extensions"];
    "/etc/asterisk/ccss.conf":;
    "/etc/asterisk/logger.conf":;
    "/etc/asterisk/modules.conf":;
    "/etc/asterisk/features.conf":;
    "/etc/asterisk/indications.conf":;
    "/etc/asterisk/manager.conf":;
    "/etc/asterisk/rtp.conf":;
    "/opt/local/bin/mib_asterisk":
      mode => 755;
    "/root/screenrc": mode => 644;
    "/var/lib/asterisk/sounds/film_operateur_netcenter.wav": mode => 644;
    "/var/lib/asterisk/sounds/film_operateur_telcocenter.wav": mode => 644;
    "/opt/local/bin/divert_support.sh":
      mode => 755;
    "/opt/local/bin/restartwhenconvenient":
      mode => 755;
  }
  add_line {
    "augmentation de la limite du nombre de file descriptor pour asterisk":
      file => "/etc/default/asterisk",
      line => "ulimit -n ${asterisk_file_descriptors}",
      require => Replace["enable_asterisk"];
  }

  exec { "reload_asterisk_extensions":
    command => "/usr/sbin/asterisk -n -rx 'dialplan reload'",
    refreshonly => true
  }
  exec { "reload_asterisk_sip":
    command => "/usr/sbin/asterisk -n -rx 'sip reload'",
    refreshonly => true
  }
  exec { "jmxterm-downloader":
    cwd   => "/root",
    command => "/opt/local/bin/jmxterm-downloader",
    unless   => "test -f /root/jmxterm-1.0-alpha-4-uber.jar",
    timeout => 3600;
  }
  exec { "restart_when_convenient":
    command => "/opt/local/bin/restartwhenconvenient",
    refreshonly => true,
    require => [ File["/opt/local/bin/restartwhenconvenient"], Service["asterisk"]];
  }
  cron {
    "restartasteriskwhenconvenient":
      command => "/opt/local/bin/restartwhenconvenient",
      user    => root,
      hour    => 3,
      minute  => 6,
      ensure  => present;
  }
  cron {
    "chankiller":
      command => "/opt/local/bin/chankiller",
      user => root,
      minute => '*/15';
  }

  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  file {
    "/etc/monitrc.d/asterisk":
      owner => root, group => root, mode => 700,
      content => template("monit/asterisk_1.8.8.erb"),
      notify => Service["monit"],
      require => [Package["monit"], Package["asterisk"]];
   "/opt/local/bin/jmxterm-downloader":
      owner => root, group => root, mode => 755,
      source => "${files_root}/voip_2_1/routag/opt/local/bin/jmxterm-downloader",
      before => Exec["jmxterm-downloader"];
   "/var/lib/asterisk/sounds/film_operateur.wav":
      ensure => link,
      target => "/var/lib/asterisk/sounds/film_operateur_${ss7_switch_location}.wav";
  }
}
