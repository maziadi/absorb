
# Classe pour un controleur de bordure VOIP de type asterisk
#

class voip_2_1::mrf(
  $active_mq_agent_password,
  $sigal_inbound_gw_channel_names,
  $sigal_outbound_gw_channel_names,
  $sigal_log_level = "INFO",
  $mrf_session_timeout = '14400',
  $sigal_maximum_pool_size = '500',
  $active_mq_si_broker_url,
  $active_mq_si_username,
  $active_mq_si_password,
  $active_mq_si_queue,
  $sip_timer_t1 = 500,
  $asterisk_t1min = 100,
  $sip_probing = 'no',
  $asterisk_file_descriptors = 8192,
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) {

  class {
      "voip_2_1::sigal-mrf-agent":
        active_mq_agent_password => $active_mq_agent_password,
        sigal_inbound_gw_channel_names => $sigal_inbound_gw_channel_names,
        sigal_outbound_gw_channel_names => $sigal_outbound_gw_channel_names,
        sigal_log_level => $sigal_log_level,
        sigal_maximum_pool_size => $sigal_maximum_pool_size,
        active_mq_si_broker_url => $active_mq_si_broker_url,
        active_mq_si_username => $active_mq_si_username,
        active_mq_si_password => $active_mq_si_password,
        active_mq_si_queue => $active_mq_si_queue,
        log_max_file_size => $log_max_file_size,
        log_max_index => $log_max_index;
  }

  define cfg_file($recurse = false, $notify = [], $content = '', $mode = 644, $ensure = file) {
    case $content {
      default: {
        file {
          "${name}":
            owner => root, group => root, mode => $mode,
            content => $content,
            require => Package["asterisk"],
            before => Service["asterisk"],
            notify => $notify,
            recurse => $recurse,
            ensure => $ensure;
        }
      }
      '' : {
        file {
          "${name}":
            owner => root, group => root, mode => $mode,
            source => [
              "${dist_files}/nodes/${hostname}/${name}",
              "${files_root}/voip_2_1/mrf/${name}"
            ],
            require => Package["asterisk"],
            before => Service["asterisk"],
            notify => $notify,
            recurse => $recurse,
            ensure => $ensure;
        }
      }
    }
  }

  package {
    "asterisk":
      ensure => present;
    "sviriosounds":
      ensure => present,
      require => Package["asterisk"];
  }
  replace {
    "enable_asterisk":
      file => "/etc/default/asterisk",
      pattern => ".*RUNASTERISK=no.*",
      replacement => "RUNASTERISK=yes",
      require => Package["asterisk"],
      before => Service["asterisk"];
  }

  cfg_file {
    "/etc/asterisk/extensions.conf":
      notify =>  Exec["reload_asterisk_extensions"];
    "/etc/asterisk/ccss.conf": notify => [];
    "/etc/asterisk/indications.conf": ;
    "/etc/asterisk/features.conf": ;
    "/etc/asterisk/logger.conf":
      notify =>  Exec["reload_asterisk_logger"];
    "/etc/asterisk/manager.conf": ;
    "/etc/asterisk/modules.conf":
      notify => Exec["restart_when_convenient"];
    "/var/lib/asterisk/sounds":
      recurse => true,
	    mode => 755,
	    ensure => directory;
    "/etc/asterisk/sip.conf":
      content => template("voip_2_1/mrf/sip.conf.erb"),
      notify => Exec["reload_asterisk_sip"];
  }

  file {
    "/etc/asterisk/manager.d":
	    mode => 755,
	    ensure => directory,
      require => Package["asterisk"]
  }
  file {
    "/etc/asterisk/manager.d/000-empty.conf":
      content => "",
	    ensure => file,
      require => File["/etc/asterisk/manager.d"]
  }
  file {
   "/opt/local/bin/jmxterm-downloader":
      owner => root, group => root, mode => 755,
      source => "${files_root}/voip_2_1/routag/opt/local/bin/jmxterm-downloader",
      before => Exec["jmxterm-downloader"]
  }
  service {
    "asterisk":
      enable => false,
      hasstatus => true,
      hasrestart => true;
  }
  exec { "reload_asterisk_extensions":
    command => "/usr/sbin/asterisk -n -rx 'dialplan reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "reload_asterisk_sip":
    command => "/usr/sbin/asterisk -n -rx 'sip reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "reload_asterisk_logger":
    command => "/usr/sbin/asterisk -n -rx 'logger reload'",
    refreshonly => true,
    require => [ Service["asterisk"]];
  }
  exec { "restart_when_convenient":
    command => "/opt/local/bin/restartwhenconvenient",
    refreshonly => true,
    require => [ File["/opt/local/bin/restartwhenconvenient"], Service["asterisk"]];
  }
  exec { "jmxterm-downloader":
    cwd   => "/root",
    command => "/opt/local/bin/jmxterm-downloader",
    unless   => "test -f /root/jmxterm-1.0-alpha-4-uber.jar",
    timeout => 3600;
  }
  add_line {
    "augmentation de la limite du nombre de file descriptor pour asterisk":
      file => "/etc/default/asterisk",
      line => "ulimit -n ${asterisk_file_descriptors}",
      require => Replace["enable_asterisk"];
  }

  class {
      "monit_1_0::monit":;
  }

  monit_1_0::monit::monit_file {
     "asterisk_1.8.8":
       requires => Package["asterisk"];
  }

  cron {
    "chankiller":
      command => "/opt/local/bin/chankiller",
      user => root,
      minute => '*/15';
  }

  cron {
    "restartasteriskwhenconvenient":
      command => "/opt/local/bin/restartwhenconvenient",
      user    => root,
      hour    => 3,
      minute  => 6,
      ensure  => present;
  }

  file {
    "/opt/local/bin/chankiller":
      owner => root, group => root, mode => 755,
      content => template("voip_2_1/mrf/chankiller.erb");
  }

  cfg_file {
      "/opt/local/bin/restartwhenconvenient":
        mode => 755,
        notify => [];
      "/opt/local/bin/mib_asterisk":
        mode => 755,
        notify => [];
      "/usr/lib/asterisk/modules/codec_g723-ast18-gcc4-glibc-x86_64-pentium4.so":
        mode => 644,
        notify => [];
      "/usr/lib/asterisk/modules/codec_g729-ast18-gcc4-glibc-x86_64-pentium4.so":
        mode => 644,
        notify => [];
      "/root/screenrc":
        mode => 644,
        notify => [];
  }
}
