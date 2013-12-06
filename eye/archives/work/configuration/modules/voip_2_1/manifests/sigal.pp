class voip_2_1::sigal_params {
  $default_karaf_max_memory = '512M'
  $default_karaf_password = "bVXxEF56"
  $sigal_log_level = "INFO"
  $sigal_maximum_pool_size = '250'
  $log_max_file_size = '20MB'
  $log_max_index = '20'
}

class voip_2_1::sigal(
  $karaf_max_memory = $voip_2_1::sigal_params::default_karaf_max_memory,
  $karaf_password = $voip_2_1::sigal_params::default_karaf_password,
  $syslog_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $local_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_maximum_pool_size = $voip_2_1::sigal_params::sigal_maximum_pool_size,
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) inherits voip_2_1::sigal_params {

  case $rsyslog_ip_service {'': { $rsyslog_ip_service = '169.254.0.160' } }

  include system_1_0::sun-jdk6

  package {
    "karaf":
      ensure => present,
      before => Service["karaf"];
  }

  file {
    "/etc/karaf/org.ops4j.pax.logging.cfg":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/org.ops4j.pax.logging.cfg.erb"),
      require => Package["karaf"];
  
  }

  file {
    "/var/lib/karaf/deploy":
      owner => karaf, group => adm,
      ensure => directory,
      recurse => true,
      require => Package["karaf"];
  }

  file {
    "/etc/default/karaf":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/karaf.erb"),
      before => Package["karaf"];
  }

  file {
    "/etc/karaf/users.properties":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/users.properties.erb"),
      require => Package["karaf"];
  }

  service {
    "karaf":
      enable => true,
      ensure => running,
      hasstatus => false,
      hasrestart => true;
  }

}

class voip_2_1::sigal-ss7-agent(
  $active_mq_agent_password,
  $sigal_inbound_gw_channel_names,
  $karaf_max_memory = $voip_2_1::sigal_params::default_karaf_max_memory,
  $karaf_password = $voip_2_1::sigal_params::default_karaf_password,
  $syslog_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_maximum_pool_size = $voip_2_1::sigal_params::sigal_maximum_pool_size,
  $ss7_provider_channel_name = 'g2',
  $ss7_own_channel_name = 'g1',
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) {

  class {
    "voip_2_1::sigal":
      karaf_max_memory => $karaf_max_memory,
      karaf_password => $karaf_password,
      syslog_log_level => $syslog_log_level,
      local_log_level => $sigal_log_level,
      sigal_maximum_pool_size => $sigal_maximum_pool_size,
      log_max_file_size => $log_max_file_size,
      log_max_index => $log_max_index;
  }

  file {
    "/etc/karaf/sigal.agent.cfg":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/ss7-agent.cfg.erb"),
      require => Package["karaf"];
  }
}

class voip_2_1::sigal-isdn-agent(
  $active_mq_agent_password,
  $sigal_inbound_gw_channel_names,
  $sigal_outbound_gw_channel_names,
  $karaf_max_memory = $voip_2_1::sigal_params::default_karaf_max_memory,
  $karaf_password = $voip_2_1::sigal_params::default_karaf_password,
  $syslog_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_maximum_pool_size = $voip_2_1::sigal_params::sigal_maximum_pool_size,
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) {

  class {
    "voip_2_1::sigal":
      karaf_max_memory => $karaf_max_memory,
      karaf_password => $karaf_password,
      syslog_log_level => $syslog_log_level,
      local_log_level => $sigal_log_level,
      sigal_maximum_pool_size => $sigal_maximum_pool_size,
      log_max_file_size => $log_max_file_size,
      log_max_index => $log_max_index;
  }

  file {
    "/etc/karaf/sigal.agent.cfg":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/isdn-agent.cfg.erb"),
      require => Package["karaf"];
  }
}

class voip_2_1::sigal-mrf-agent(
  $active_mq_agent_password,
  $sigal_inbound_gw_channel_names,
  $sigal_outbound_gw_channel_names,
  $karaf_max_memory = $voip_2_1::sigal_params::default_karaf_max_memory,
  $karaf_password = $voip_2_1::sigal_params::default_karaf_password,
  $syslog_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_maximum_pool_size = '500',
  $active_mq_si_broker_url,
  $active_mq_si_username,
  $active_mq_si_password,
  $active_mq_si_queue,
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) {

  class {
    "voip_2_1::sigal":
      karaf_max_memory => $karaf_max_memory,
      karaf_password => $karaf_password,
      syslog_log_level => $syslog_log_level,
      local_log_level => $sigal_log_level,
      sigal_maximum_pool_size => $sigal_maximum_pool_size,
      log_max_file_size => $log_max_file_size,
      log_max_index => $log_max_index;
  }

  file {
    "/etc/karaf/sigal.agent.cfg":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/mrf-agent.cfg.erb"),
      require => Package["karaf"];
  }
}

class voip_2_1::sigal-as(
  $active_mq_as_password,
  $active_mq_max_memory = '256M',
  $karaf_max_memory = $voip_2_1::sigal_params::default_karaf_max_memory,
  $karaf_password = $voip_2_1::sigal_params::default_karaf_password,
  $syslog_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $sigal_log_level = $voip_2_1::sigal_params::sigal_log_level,
  $log_max_file_size = $voip_2_1::sigal_params::log_max_file_size,
  $log_max_index = $voip_2_1::sigal_params::log_max_index
  ) {

  class {
    "voip_2_1::sigal":
      karaf_max_memory => $karaf_max_memory,
      karaf_password => $karaf_password,
      syslog_log_level => $syslog_log_level,
      local_log_level => $sigal_log_level,
      log_max_file_size => $log_max_file_size,
      log_max_index => $log_max_index;
  }

  include mysql_1_0::mysql

  file {
    "/etc/karaf/sigal.as.cfg":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/as.cfg.erb"),
      require => Package["karaf"];
    "/opt/local/share/sigal":
      owner => root, group => root, mode => 755,
      ensure => directory;
    "/opt/local/share/sigal/schema.sql":
      owner => root, group => root, mode => 644,
      source => "${files_root}/voip_2_1/sigal/opt/local/share/sigal/schema.sql",
      require => File["/opt/local/share/sigal"];
  }

  mysql_1_0::mysql::mysql_db {
    "as":
      username => "as",
      password => $sigal_as_db_password,
      init_file => "/opt/local/share/sigal/schema.sql",
      require => File["/opt/local/share/sigal/schema.sql"];
  }
}

class voip_2_1::sigal-cdrarchiver  {
  include monit 
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  package {
    "cdr-archiver-cbv1":
      ensure => present;
    "cdr-archiver-cbv2":
      ensure => present;
  }

  file {
    "/var/lib/cdr":
      owner => root, group => root, mode => 755,
      ensure => directory;
    "/etc/default/cdr-archiver-cbv1":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/cdr-archiver-cbv1.erb"),
      require => Package["cdr-archiver-cbv1"];
    "/etc/default/cdr-archiver-cbv2":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/sigal/cdr-archiver-cbv2.erb"),
      require => Package["cdr-archiver-cbv2"];
    "/etc/monitrc.d/cdr-archiver-cbv1":
      owner => root, group => root, mode => 700,
      content => template("monit/cdr-archiver-cbv1.erb"),
      notify => Service["monit"],
      require => [Package["monit"], Package["cdr-archiver-cbv1"], File["/var/lib/cdr"]];
    "/etc/monitrc.d/cdr-archiver-cbv2":
      owner => root, group => root, mode => 700,
      content => template("monit/cdr-archiver-cbv2.erb"),
      notify => Service["monit"],
      require => [Package["monit"], Package["cdr-archiver-cbv2"], File["/var/lib/cdr"]];
  }

  cron {
    "CdrArchiver-cbv1":
      hour => 3,
      minute => 6,
      command => "/bin/kill -HUP `cat /var/run/cdr-archiver-cbv1d.pid`";
    "CdrArchiver-cbv2":
      hour => 3,
      minute => 6,
      command => "/bin/kill -HUP `cat /var/run/cdr-archiver-cbv2d.pid`";
  }
}
