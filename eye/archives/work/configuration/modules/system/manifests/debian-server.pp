class system::debian-server {
  include system::debian, openntpd, admin_users, system::ssh_authorized_keys, ssmtp, snmpd, syslog-ng
}
