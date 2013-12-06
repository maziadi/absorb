class voip_2_1::mobicents (
$mobicents_version = "2.0.0-2",
$java_max_heap_size = '2048m',
$jboss_managment_addr = '127.0.0.1',
$mobicents_service_addr,
$mobicents_service_port = 5060,
$rsyslog_ip_service = '169.254.0.160',
$admin_user = 'managementUser',
$admin_passwd = 'CEIhu26YIAmFU',
$sip_timer_t1 = '500',
$log_max_file_size = '20m',
$log_max_index = 20,
$dar_path,
$config_path,
$local_log_level = 'INFO',
$syslog_log_level = 'INFO'
) {

  $jboss_service_addr = $mobicents_service_addr

# NB: JBoss could be moved to another module if it is needed elsewhere.

  user {
    "jboss-as"	:
      ensure => present,
      home	 => '/opt/mobicents',
      system => true;
  }

  file {
    "/opt/local/bin/mobicents-install":
      owner => root, group => root, mode => 700,
      content => template("voip_2_1/mobicents/mobicents-install.erb"),
      require => User["jboss-as"],
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/configuration/standalone.xml":
      owner => jboss-as, group => root, mode => 644,
      content => template($config_path),
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/opt/mobicents/bin/standalone.conf":
      owner => jboss-as, group => root, mode => 644,
      content => template("voip_2_1/mobicents/standalone.conf.erb"),
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/etc/init.d/jboss-as":
      owner => root, group => root, mode => 755,
      source => "${files_root}/voip_2_1/mobicents/etc/init.d/jboss-as",
      before => Service["jboss-as"];
    "/etc/default/jboss-as":
      owner => root, group => root, mode => 644,
      content => template("voip_2_1/mobicents/jboss-as.erb"),
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/configuration/dars/mobicents-dar.properties":
      owner => jboss-as, group => root, mode => 644,
      source => $dar_path,
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/deployments":
      ensure => directory,
      recurse => true,
      owner => jboss-as, group => admin, mode => 750,
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/configuration":
      ensure => directory,
      recurse => true,
      owner => jboss-as, group => admin, mode => 750,
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/tmp":
      ensure => directory,
      recurse => true,
      owner => jboss-as, group => admin, mode => 750,
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/data":
      ensure => directory,
      recurse => true,
      owner => jboss-as, group => admin, mode => 750,
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/opt/mobicents/standalone/log":
      ensure => directory,
      recurse => true,
      owner => jboss-as, group => admin, mode => 750,
      require => [User["jboss-as"], Exec["mobicents-install"]],
      before => Service["jboss-as"];
    "/var/log/jboss-as":
      ensure => link,
      owner => jboss-as, group => adm, mode => 755,
      target => '/opt/mobicents/standalone/log',
      require => [User["jboss-as"], Exec["mobicents-install"], File["/opt/mobicents/standalone/log"]],
      before => Service["jboss-as"];
  }

  exec {
    "mobicents-install":
      cwd     => "/tmp",
      command => "/opt/local/bin/mobicents-install",
      timeout => 3600,
      unless  => "test -f /etc/mobicents-installed-${mobicents_version}",
      require => [User["jboss-as"], File["/opt/local/bin/mobicents-install"]];
    "create-management-user":
      cwd     => "/tmp",
      command => "/opt/mobicents/bin/add-user.sh --silent ${admin_user} ${admin_passwd}",
      timeout => 3600,
      unless  => "grep -Eq '${admin_user}=.+' /opt/mobicents/standalone/configuration/mgmt-users.properties",
      require => Exec["mobicents-install"];
  }

  service {
    "jboss-as":
      enable => false,
      hasstatus => true,
      hasrestart => true,
      require => [Exec["mobicents-install"], File["/etc/init.d/jboss-as"]];
  }
}
