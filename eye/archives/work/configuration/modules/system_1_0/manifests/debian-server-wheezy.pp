class system_1_0::debian-server-wheezy ($rpcbind = false) {
  include system_1_0::debian, ntp_2_0::client, admin_users, system_1_0::ssh_authorized_keys, ssmtp, snmpd_1_0::snmpd-wheezy, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd
  if $rpcbind {
    package {
      "rpcbind": ensure => present;
    }
  } else {
    package {
      "rpcbind": ensure => absent;
    }
  }
  package {
    "avahi-daemon": ensure => absent;
  }
}

class system_1_0::debian-server-wheezy-nouser {
  include system_1_0::debian, ntp_2_0::client, system_1_0::ssh_authorized_keys, ssmtp, snmpd_1_0::snmpd-wheezy, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd
  package {
    "avahi-daemon": ensure => absent;
    "portmap": ensure => absent;
  }
}

class system_1_0::debian-server-wheezy-nontp {
  include system_1_0::debian, system_1_0::ssh_authorized_keys, ssmtp, snmpd_1_0::snmpd-wheezy, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd
  package {
    "avahi-daemon": ensure => absent;
    "portmap": ensure => absent;
  }
}

class system_1_0::debian-server-wheezy-davfi {
  include system_1_0::debian, ntp_2_0::client, ssmtp, snmpd_1_0::snmpd-wheezy, rsyslog_1_0::rsyslog-client, smart_1_0::tools, ssh_1_0::sshd, davfi_users
  package {
    "avahi-daemon": ensure => absent;
    "portmap": ensure => absent;
  }
}
