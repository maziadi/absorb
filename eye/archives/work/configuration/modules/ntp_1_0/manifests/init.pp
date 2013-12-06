#modules ntp_1_0
# les surcharges ne seront plus utiles lorsque la migration vers system_1_0 sera complete
class ntp_1_0::server inherits ntp_2_0::client {

  case $ntp_1_0_peer { ''  : {$ntp_1_0_peer = '' } }
 
  File["/etc/ntp.conf"]{
    content => template("ntp_1_0/ntp.conf.erb")
  }
}

class ntp_1_0::client {
# a supprimer lorsque tous les nodes utiliseront systeme_1_0
  case $openntpd_servers { 
    ''      : {
                $openntpd_servers = []
                $openntpd_alphalink = true
              } 
    default : {$openntpd_alphalink = false }
  }

  package { "openntpd":  
    ensure => present,
    before => File["/etc/ntpd.conf"]
  }

  service { "openntpd":
    name => $operatingsystem ? {
      debian => "openntpd",
      Ubuntu => "openntpd",
      Gentoo => "ntpd"
    },
    enable => true,
    hasrestart => true,
    ensure => running,
    pattern => '/ntpd',
    subscribe => File["/etc/ntpd.conf"]
  }

  file { "/etc/ntpd.conf":
    name => $operatingsystem ? {
      debian => "/etc/openntpd/ntpd.conf",
      Ubuntu => "openntpd",
      Gentoo => "/etc/ntpd.conf"
    },
    content => template("ntp_1_0/ntpd.conf.erb"),
    before => Service["openntpd"]
  }

 replace {
  "/etc/default/openntpd":
    file => "/etc/default/openntpd",
    pattern => "#DAEMON_OPTS=\"-s\"",
    replacement => "DAEMON_OPTS=\"-s\"",
    notify => Service["openntpd"];
  }
}

class ntp_2_0::client  {
  
  package { 
    "openntpd":
    ensure => purged
  }

 # File["/etc/ntpd.conf"] { 
 #   ensure => absent
 # }

  package {
    "ntp": 
      ensure => present,
      before => File["/etc/ntp.conf"];
  }
  
  file {
    "/etc/ntp.conf":
      content => template("ntp_1_0/ntp-client.conf.erb"),
      before  => Service["ntp"],
      notify  => Service["ntp"];
  }
  service {
    "ntp":
      pattern => "/ntpd",
      ensure => running;
  }  
}
