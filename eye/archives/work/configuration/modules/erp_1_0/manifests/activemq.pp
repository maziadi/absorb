class erp_1_0::activemq (
    $active_mq_erp_login,
    $active_mq_erp_password, 
    $active_mq_erp_queue 
    ) inherits activemq_1_0::activemq {
  File["/opt/local/apache-activemq-${active_mq_version}/conf/activemq.xml"] {
    owner => activemq, group => activemq, mode => 600,
    content => template("erp_1_0/activemq/activemq.xml.erb"),
    require => Exec["active-mq-install"]
  }
}
