class system_1_0::debian-server-squeeze ($portmap = false){
  include system_1_0::debian, ntp_2_0::client, admin_users, system_1_0::ssh_authorized_keys, ssmtp, snmpd_1_0::snmpd-squeeze, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd
  if $portmap {
    package {
      "portmap": ensure => present;
    }
  } else {
    package {
      "portmap": ensure => absent;
    }
  }
  package {
    "avahi-daemon": ensure => absent;
  }
}

class system_1_0::debian-server-squeeze-nouser {
  include system_1_0::debian, ntp_2_0::client, system_1_0::ssh_authorized_keys, ssmtp, snmpd_1_0::snmpd-squeeze, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd
  package {
    "avahi-daemon": ensure => absent;
    "portmap": ensure => absent;
  }
}

class system_1_0::debian-server-squeeze-nontp {
  include system_1_0::debian, system_1_0::ssh_authorized_keys, ssmtp, snmpd_1_0::snmpd-squeeze, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd
  package {
    "avahi-daemon": ensure => absent;
    "portmap": ensure => absent;
  }
}

class system_1_0::dev-pornic-squeeze {
  $rsyslog_ip_service = '10.2.44.50'
  #TODO : to be completed

  include system_1_0::debian-server-squeeze
}
