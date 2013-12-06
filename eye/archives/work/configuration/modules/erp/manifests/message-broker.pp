#
# Deploiement de ActiveMQ
#
class erp::message-broker inherits activemq_1_0::activemq {
  case $active_mq_test { '': { $active_mq_test = false } }
  File["/opt/local/apache-activemq-${active_mq_version}/conf/activemq.xml"] {
    owner => activemq, group => activemq, mode => 600,
    content => template("erp/message-broker/activemq.xml.erb"),
    require => Exec["active-mq-install"]
  }

}
