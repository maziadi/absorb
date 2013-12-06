#
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

# $active_mq_no_flowcontrol (optionnal)

class activemq_1_1::activemq_params {
  $active_mq_version = "5.5.1"
  $active_mq_jmx_password = "kaoHaes0iote"
  $active_mq_service_addr = "localhost"
  $active_mq_monit_addr = "localhost"
  $active_mq_stomp_port = 61613
  $active_mq_admin_password = "uoRkSL8cqP"
  $active_mq_monit_password = $active_mq_monit_password
  $active_mq_user_login = ""
  $active_mq_user_password = ""
  $active_mq_second_user_login = ""
  $active_mq_second_user_password = ""
  $active_mq_topic = []
  $active_mq_queue = []
  $active_mq_second_queue = []
  $active_mq_connector_url = false
  $active_mq_max_memory = '256M'
  $active_mq_xml_template = "activemq_1_1/activemq.xml.erb"
  $active_mq_java_conf_template =  "activemq_1_1/activemq.conf.erb"
  $active_mq_pers_store_value = "512 mb"
  $active_mq_temp_store_value = "128 mb"
  $active_mq_mem_usage_value = "32"
  $active_mq_no_flowcontrol = []
}

class activemq_1_1::activemq (
  $active_mq_version = $activemq_1_1::activemq_params::active_mq_version,
  $active_mq_jmx_password = $activemq_1_1::activemq_params::active_mq_jmx_password,
  $active_mq_service_addr = $activemq_1_1::activemq_params::active_mq_service_addr,
  $active_mq_monit_addr = $activemq_1_1::activemq_params::active_mq_monit_addr,
  $active_mq_stomp_port = $activemq_1_1::activemq_params::active_mq_stomp_port,
  $active_mq_admin_password = $activemq_1_1::activemq_params::active_mq_admin_password,
  $active_mq_monit_password = $activemq_1_1::activemq_params::active_mq_monit_password,
  $active_mq_user_login = $activemq_1_1::activemq_params::active_mq_user_login,
  $active_mq_user_password = $activemq_1_1::activemq_params::active_mq_user_password,
  $active_mq_second_user_login = $activemq_1_1::activemq_params::active_mq_second_user_login,
  $active_mq_second_user_password = $activemq_1_1::activemq_params::active_mq_second_user_password,
  $active_mq_topic = $activemq_1_1::activemq_params::active_mq_topic,
  $active_mq_queue = $activemq_1_1::activemq_params::active_mq_queue,
  $active_mq_second_queue = $activemq_1_1::activemq_params::active_mq_queue,
  $active_mq_connector_url = $activemq_1_1::activemq_params::active_mq_connector_url,
  $active_mq_max_memory = $activemq_1_1::activemq_params::active_mq_max_memory,
  $active_mq_xml_template = $activemq_1_1::activemq_params::active_mq_xml_template,
  $active_mq_java_conf_template = $activemq_1_1::activemq_params::active_mq_java_conf_template,
  $active_mq_pers_store_value = $activemq_1_1::activemq_params::active_mq_pers_store_value,
  $active_mq_no_flowcontrol = $activemq_1_1::activemq_params::active_mq_no_flowcontrol,
  $active_mq_temp_store_value = $activemq_1_1::activemq_params::active_mq_temp_store_value,
  $active_mq_mem_usage_value = $activemq_1_1::activemq_params::active_mq_mem_usage_value
) inherits activemq_1_1::activemq_params {

  include system_1_0::sun-jdk6

  file {
    "/opt/local/bin/active-mq-install":
      owner => root, group => root, mode => 700,
      content => template("activemq_1_1/active-mq-install.erb");
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
      source => "${files_root}/activemq_1_1/activemq.init";
    "/etc/activemq.conf":
      owner => activemq, group => activemq, mode => 600,
      content => template($active_mq_java_conf_template);
    # patch du fichier pour permettre le fonctionnement du stop JMX
    "/opt/local/apache-activemq-${active_mq_version}/bin/activemq-admin":
      owner => activemq, group => activemq, mode => 755,
      source => "${files_root}/activemq_1_1/activemq-admin",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/activemq.xml":
      owner => activemq, group => activemq, mode => 600,
      content => template($active_mq_xml_template),
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/log4j.properties":
      owner => activemq, group => activemq, mode => 600,
      source => "${files_root}/activemq_1_1/log4j.properties",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/credentials.properties":
      owner => activemq, group => activemq, mode => 600,
      source => "${files_root}/activemq_1_1/credentials.properties",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/jmx.password":
      owner => activemq, group => activemq, mode => 600,
      content => "monitorRole $active_mq_jmx_password\ncontrolRole $active_mq_jmx_password\n",
      require => Exec["active-mq-install"];
    "/opt/local/apache-activemq-${active_mq_version}/conf/jmx.access":
      owner => activemq, group => activemq, mode => 600,
      content => "monitorRole readonly\ncontrolRole readwrite\n",
      require => Exec["active-mq-install"];
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
  
  monit_1_0::monit::monit_file {
    "activemq":
      requires => Service["activemq"];
  }

}
