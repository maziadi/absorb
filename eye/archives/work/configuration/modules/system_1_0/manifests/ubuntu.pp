class system_1_0::ubuntu-server {
  $snmpd_options = "Ls6d"
  include system_1_0::debian-server
  package {
    [
      "consolekit" 
    ]: ensure => absent;
    [
      "man",
    ]: ensure => present;
  }
  # valable pour hardy, pour les versions suivantes suivre
  # https://help.ubuntu.com/community/SerialConsoleHowto
  file {
    "/etc/event.d/ttyS0":
      source => "${files_root}/system_1_0/ubuntu_ttyS0",
      mode => 644, owner => root, group => root;
  }
}
