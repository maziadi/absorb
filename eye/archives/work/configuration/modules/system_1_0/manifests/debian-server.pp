class system_1_0::debian-server {
  case $enabled_ssmtp { '': { $enabled_ssmtp = true } }
  include system_1_0::debian, ntp_2_0::client, admin_users, system_1_0::ssh_authorized_keys, snmpd_1_0::snmpd, syslog-ng, smart_1_0::tools, ssh_1_0::sshd
  package {
    "avahi-daemon": ensure => absent;
    "portmap": ensure => absent;
    "nfs-common": ensure => absent;
  }
  if $enabled_ssmtp {
    include ssmtp
  }
}
