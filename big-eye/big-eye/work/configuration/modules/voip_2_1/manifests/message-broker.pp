#
# Deploiement de ActiveMQ
#
# Variables:
# $active_mq_service_addr (default)
# $active_mq_jmx_password (default)
#
# $active_mq_admin_password (required)
# $active_mq_agent_password (required)
# $active_mq_as_password (required)
# $active_mq_operator_password (required)
#
# $active_mq_connector_url (optionnal)
#
class voip_2_1::message-broker(
    $active_mq_service_addr,
    $active_mq_admin_password,
    $active_mq_max_memory,
    $active_mq_monit_addr,
    $active_mq_monit_password,
    $active_mq_pers_store_value
    ) {
  class {
    "activemq_1_1::activemq":
      active_mq_service_addr => $active_mq_service_addr,
      active_mq_admin_password => $active_mq_admin_password,
      active_mq_max_memory => $active_mq_max_memory,
      active_mq_monit_addr => $active_mq_monit_addr,
      active_mq_monit_password => $active_mq_monit_password,
      active_mq_xml_template => "voip_2_1/message-broker/activemq.xml.erb",
      active_mq_pers_store_value => $active_mq_pers_store_value;
  }
}
