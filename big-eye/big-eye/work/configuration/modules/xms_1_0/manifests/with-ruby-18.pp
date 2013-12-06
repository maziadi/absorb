class xms_1_0::with-ruby-18 (
    $db_name="",
    $db_host="127.0.0.1",
    $db_user="ucp",
    $db_password="ucp_password",
    $ucp_sc="",
    $ucp_password="",
    $ucp_gateway="", #kiosque gateway
    $ucp_port="4444",
    $ucp_conn_attempt="5",
    $stomp_username="",
    $stomp_password="",
    $stomp_host="",
    $stomp_port="",
    $stomp_ssl="",
    $stomp_suscribe="",
    $stomp_selector="",
    $db_version="9.1",
    $monitor_ucpdaemon=true,
    $monitor_sidaemon=true
){

  package {
    "dnsutils":
      ensure => present;
    "ruby1.8-full":
      ensure => present;
    "ruby-libxms":
      ensure => present;
    "ucpdaemon":
      ensure => present;
    "sidaemon":
      ensure => present,
      require => Package["ucpdaemon"];

  }

  postgresql_1_0::db {
        $db_name:
        owner => $db_user,
        password => $db_password,
        require => Package["ucpdaemon"];
  }

  file {
    "/etc/default/sidaemon":
      content => template("xms_1_0/sidaemon/sidaemon.default.erb"),
      owner => root, group => root, mode => 644,
      require => Package["sidaemon"];
    "/etc/ucp/ucp.conf":
      content => template("xms_1_0/ucpdaemon/ucp.conf.erb"),
      owner => root, group => root, mode => 644,
      require => Package["ucpdaemon"];
  }

  class {
    "monit_1_0::monit":;
  }

  if $monitor_sidaemon {
    monit_1_0::monit::monit_file {
      "sidaemon":
        requires => Package["sidaemon"];
    }
  }
  else {
    file {
     "/etc/monit/conf.d/sidaemon":
      ensure => absent;
    }
  }

  if $monitor_ucpdaemon {
    monit_1_0::monit::monit_file {
      "ucpdaemon":
        requires => Package["ucpdaemon"];
    }
  }
  else {
    file {
      "/etc/monit/conf.d/ucpdaemon":
        ensure => absent;
    }
  }

}
