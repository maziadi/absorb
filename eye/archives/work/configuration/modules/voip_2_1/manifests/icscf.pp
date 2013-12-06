class voip_2_1::icscf (
$service_addr,
$active_mq_agent_password,
$sigal_maximum_pool_size = 2000,
$java_max_heap_size  = '2048m',
$sip_servlet_container = 'mobicents',
$mobicents_session_duration = 256,
$call_max_duration = 240,
$rsyslog_ip_service = '169.254.0.160',
$log_max_file_size = '20m',
$log_max_index = 20,
$sip_timer_t1 = 500,
$icscf_war_version = "1.0.0",
$mobicents_version = "2.0.0-2",
$local_log_level = 'INFO',
$syslog_log_level = 'INFO'
) {
  class {
  "monit_1_0::monit":;
  "system_1_0::sun-jdk6":;
  "voip_2_1::mobicents":
    mobicents_version      => $mobicents_version,
    java_max_heap_size     => $java_max_heap_size,
    sip_timer_t1           => $sip_timer_t1,
    log_max_file_size      => $log_max_file_size,
    log_max_index          => $log_max_index,
    dar_path => "${files_root}/voip_2_1/icscf/opt/mobicents/standalone/configuration/dars/mobicents-dar.properties",
    mobicents_service_addr => $service_addr,
    rsyslog_ip_service     => $rsyslog_ip_service,
    local_log_level        => $local_log_level,
    syslog_log_level       => $syslog_log_level,
    config_path            => "voip_2_1/icscf/standalone.xml.erb";
  }

  exec {
    "icscf_war-install":
      cwd => "/tmp",
      command => "/opt/local/bin/icscf_war-install",
      timeout => 3600,
      unless => "test -f /etc/icscf_war-installed-${icscf_war_version}",
      # notify => Service["mobicents"], # war is reloaded when it changes
      require => [File["/opt/local/bin/icscf_war-install"], Class["voip_2_1::mobicents"]];
  }

  file {
    "/etc/icscf":
      owner => jboss-as, group => jboss-as, mode => 750,  
      ensure => directory,
      require => Class["voip_2_1::mobicents"];
    "/etc/icscf/spring.properties":
      owner => jboss-as, group => jboss-as, mode => 640,
      content => template("voip_2_1/icscf/spring.properties.erb"),
      require => Class["voip_2_1::mobicents"];
    "/etc/icscf/hosts.properties":
      owner => jboss-as, group => jboss-as, mode => 640,
      content => template("voip_2_1/icscf/hosts.properties.erb"),
      require => Class["voip_2_1::mobicents"];
    "/opt/local/bin/icscf_war-install":
      owner => root, group => root, mode => 755,
      content => template("voip_2_1/icscf/icscf_war-install.erb"),
      before => Exec["icscf_war-install"];
    "/var/log/icscf":
      ensure => link,
      owner => jboss-as, group => adm, mode => 755,
      target => '/var/log/jboss-as',
      require => Class["voip_2_1::mobicents"];
    "/opt/local/bin/jmxterm-downloader":
      owner => root, group => root, mode => 755,
      source => "${files_root}/voip_2_1/icscf/opt/local/bin/jmxterm-downloader",
      before => Exec["jmxterm-downloader"];
    "/root/screenrc":
      mode => 644,
      source => "${files_root}/voip_2_1/icscf/root/screenrc",
      notify => [];
  }

  exec {
    "jmxterm-downloader":
      cwd   => "/root",
      command => "/opt/local/bin/jmxterm-downloader",
      unless   => "test -f /root/jmxterm-1.0-alpha-4-uber.jar",
      timeout => 3600;
  }

  monit_1_0::monit::monit_file {
    "icscf":
      require => Service["jboss-as"]; 
  }

}
