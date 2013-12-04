#modules dev-pornic
class dev-pornic::server {
  include rsyslog::rsyslog-client
  $rsyslog_ip_service = '10.2.44.50'
}
