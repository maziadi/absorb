class voip_2_1::routag  (
$routag_service_addr = false,
$routag_service_port = "5060",
$routag_db_user = 'routag',
$routag_db_password = 'QuLPdlEO9L',
$java_max_heap_size = "2048m",
$routag_war_version = "1.1.2",
$routag_session_timeout = '256',
$rsyslog_ip_service = '169.254.0.160',
$admin_user = 'managementUser',
$admin_passwd = 'CEIhu26YIAmFU',
$log_max_file_size = '20m',
$log_max_index = 20,
$sip_timer_t1 = 500,
$mobicents_version = "2.0.0-2",
$local_log_level = 'INFO',
$syslog_log_level = 'INFO'
) {

  include mysql_1_0::mysql

  class {
    "voip_2_1::mobicents":
    mobicents_version      => $mobicents_version,
    java_max_heap_size     => $java_max_heap_size,
    jboss_managment_addr	 => '127.0.0.1',
    mobicents_service_addr => $routag_service_addr,
    mobicents_service_port => $routag_service_port,
    rsyslog_ip_service     => $rsyslog_ip_service,
    admin_user             => $admin_user,
    admin_passwd           => $admin_passwd,
    sip_timer_t1           => $sip_timer_t1,
    log_max_file_size      => $log_max_file_size,
    log_max_index          => $log_max_index,
    local_log_level        => $local_log_level,
    syslog_log_level       => $syslog_log_level,
    dar_path               => "${files_root}/voip_2_1/routag/opt/mobicents/standalone/configuration/dars/mobicents-dar.properties",
    config_path            => "voip_2_1/routag/standalone.xml.erb";
  }
  exec {
    "routag_war-install":
    cwd => "/tmp",
    command => "/opt/local/bin/routag_war-install",
    timeout => 3600,
    unless => "test -f /etc/routag_war-installed-${routag_war_version}",
      # notify => Service["mobicents"], # war is reloaded when it changes
      require => File["/opt/local/bin/routag_war-install"];
  }
  file {
    "/var/log/routag":
    ensure => link,
      owner => jboss-as, group => adm, mode => 755,
      target => '/var/log/jboss-as',
      require => Class["voip_2_1::mobicents"],
  }
  monit_1_0::monit::monit_file {
    "routag":
    require => Service["jboss-as"]; 
  }

  mysql_1_0::mysql::mysql_db {
    'routag':
      username => 'routag',
      password => $routag_db_password;
  }

  file {
    "/opt/local/share/routag":
      owner => root, group => root, mode => 750,  
      ensure => directory;
    "/opt/local/share/routag/routag.sql":
      owner => root, group => root, mode => 644,
      content => "CREATE TABLE `routag` (
  `carrier_code` varchar(15) NOT NULL,
  `prefix_min` varchar(17) NOT NULL,
  `prefix_max` varchar(17) NOT NULL,
  `weight` int(3) NOT NULL,
  `strip` int(2) NOT NULL,
  `rewrite_prefix` varchar(16) default NULL,
  `destination_code` varchar(15) default NULL,
  `trunk_group_id` int(10) unsigned default NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;",
      require => File["/opt/local/share/routag"];
    "/opt/local/share/routag/trunk_group.sql":
      owner => root, group => root, mode => 644,
      content => "CREATE TABLE `trunk_group` (
  `id` int(10) unsigned default NULL,
  `host` varchar(64) default NULL,
  `weight` int(3) NOT NULL,
  `update_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `enabled` boolean NOT NULL default true,
  KEY `trunk_group_id` (`id`)                                                                                                                                                       
) ENGINE=InnoDB DEFAULT CHARSET=latin1;",
      require => File["/opt/local/share/routag"];
    "/etc/logrotate.d/routag":
      source => "${files_root}/voip_2_1/routag/etc/logrotate.d/routag",
      mode => 644, owner => root, group => root;
   "/opt/local/bin/jmxterm-downloader":
      owner => root, group => root, mode => 755,
      source => "${files_root}/voip_2_1/routag/opt/local/bin/jmxterm-downloader",
      before => Exec["jmxterm-downloader"];
   "/opt/local/bin/routag_war-install":
      owner => root, group => root, mode => 755,
      content => template("voip_2_1/routag/routag_war-install.erb"),
      before => Exec["routag_war-install"];
  }

  mysql_1_0::mysql::mysql_schema { 
    "routag table":
      db => 'routag', username => $routag_db_user, password => $routag_db_password,
      file => '/opt/local/share/routag/routag.sql',
      check_table => 'routag',
      require => File["/opt/local/share/routag/routag.sql"];
    "trunk_group table":
      db => 'routag', username => $routag_db_user, password => $routag_db_password,
      file => '/opt/local/share/routag/trunk_group.sql',
      check_table => 'trunk_group',
      require => File["/opt/local/share/routag/trunk_group.sql"];
  } 

  exec {
    "jmxterm-downloader":
      cwd   => "/root",
      command => "/opt/local/bin/jmxterm-downloader",
      unless   => "test -f /root/jmxterm-1.0-alpha-4-uber.jar",
      timeout => 3600;
  }
}
