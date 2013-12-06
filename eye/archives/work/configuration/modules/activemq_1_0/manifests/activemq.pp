#
# Deploiement de ActiveMQ
#
# Variables:
# $active_mq_service_addr (default)
# $active_mq_jmx_password (default)
#
# $active_mq_admin_password (optionnal)
# $active_mq_monit_password (optionnal)
# $active_mq_connector_url (optionnal)
#
# $active_mq_user_login (required)
# $active_mq_user_password (required)
# $active_mq_queue (optionnal)
# $active_mq_topic (optionnal)

class activemq_1_0::activemq {
  $active_mq_version = "5.3.1"
  $active_mq_jmx_password = "kaoHaes0iote"
  case $active_mq_service_addr { '': { $active_mq_service_addr = "localhost" } }
  case $active_mq_monit_addr { '': { $active_mq_monit_addr = $active_mq_service_addr } }
  case $active_mq_stomp_port { '': { $active_mq_stomp_port = 61613 } }
  case $active_mq_admin_password { '':  { $active_mq_admin_password = "uoRkSL8cqP" } }
  case $active_mq_monit_password { '': { $active_mq_monit_password = "S8Gi6sQuu6" } }
  case $active_mq_user_login { '':  { $active_mq_user_login = "" } }
  case $active_mq_user_password { '':  { $active_mq_user_password = "" } }

  case $active_mq_topic { '': { $active_mq_topic = false } }
  case $active_mq_queue { '': { $active_mq_queue = false } }
  case $active_mq_connector_url { 
    '': {
      $active_mq_connector_url = false
    }
    default: {
      case $active_mq_bridge_password {
        '': {
          fail("active_mq_bridge_password is required !\n")
        }
      }
    }
  }

  include system_1_0::sun-jdk6
  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  file {
    "/opt/local/bin/active-mq-install":
      owner => root, group => root, mode => 700,
      content => template("activemq_1_0/active-mq-install.erb");
    "/var/log/activemq":
      owner => activemq, group => activemq, mode => 750,
      ensure => directory,
      require => User["activemq"];
    "/var/lib/activemq-data":
      owner => activemq, group => activemq, mode => 750,
      ensure => directory,
      require => User["activemq"];
    "/etc/init.d/activemq":
      owner => root, group => root, mode => 755,
      source => "${files_root}/activemq_1_0/activemq.init";
    "/etc/activemq.conf":
      owner => activemq, group => activemq, mode => 600,
      content => template("activemq_1_0/activemq.conf.erb");
    # patch du fichier pour permettre le fonctionnement du stop JMX
    "/opt/local/apache-activemq-${active_mq_version}/bin/activemq-admin":
      owner => activemq, group => activemq, mode => 755,
      source => "${files_root}/activemq_1_0/activemq-admin",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/activemq.xml":
      owner => activemq, group => activemq, mode => 600,
      content => template("activemq_1_0/activemq.xml.erb"),
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/log4j.properties":
      owner => activemq, group => activemq, mode => 600,
      source => "${files_root}/activemq_1_0/log4j.properties",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/credentials.properties":
      owner => activemq, group => activemq, mode => 600,
      source => "${files_root}/activemq_1_0/credentials.properties",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/jmx.password":
      owner => activemq, group => activemq, mode => 600,
      content => "monitorRole $active_mq_jmx_password\ncontrolRole $active_mq_jmx_password\n",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/jmx.access":
      owner => activemq, group => activemq, mode => 600,
      content => "monitorRole readonly\ncontrolRole readwrite\n",
      require => Exec["active-mq-install"];
    "/etc/monitrc.d/activemq":
      owner => root, group => root, mode => 700, 
      content => template("monit/activemq.erb"),
      notify => Service["monit"],
      require => [ Package["monit"],Exec["active-mq-install"]];
  }


  group {
    "activemq":
      ensure  => "present",
      gid     => "1004"
  }

  user {
    "activemq":
      ensure  => "present",
      uid     => "1004",
      gid     => "1004",
      comment => "ActiveMQ User",
      home    => "/opt/local/",
      shell   => "/bin/false",
      require => Group["activemq"]
  }

  exec {
    "active-mq-install":
      cwd   => "/tmp",
      command => "/opt/local/bin/active-mq-install",
      timeout => 3600,
      unless   => "test -f /etc/activemq-installed-${active_mq_version}",
      require => [User["activemq"],File["/opt/local/bin/active-mq-install"],File["/var/lib/activemq-data"],File["/var/log/activemq"]];
  }

  service {
    "activemq":
      enable => true,
      ensure  => running,
      hasrestart => true,
      pattern => '/run.jar start',
      require => [Exec["active-mq-install"], File["/etc/init.d/activemq"]];
  }
}
