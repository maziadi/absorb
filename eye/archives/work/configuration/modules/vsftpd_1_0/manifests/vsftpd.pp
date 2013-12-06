class vsftpd::base {
  }

class vsftpd::vserver { 
#class vsftpd::vserver inherits vsftpd::base {
  case $vsftpd_guest_username {'': { $vsftpd_guest_username = "vsftpd" } }
  case $vsftpd_banner {'': { $vsftpd_banner = true } }
  std_user { "vsftpd": key => ""; }

  file {
    "/etc/vsftpd.conf":
      owner => root, group => root, mode => 600,
      content => template("vsftpd_1_0/vsftpd.conf.vserver.erb"),
      before => Service["vsftpd"],
      require => Package["vsftpd"];
    "/etc/pam.d/vsftpd":
      source => "${files_root}/vsftpd_1_0/vsftpd.pam",
      owner => root, group => root, mode => 600,
      before => Service["vsftpd"],
      require => Package["vsftpd"];
    "/etc/vsftpd_login.db":
      source => "${files_root}/vsftpd_1_0/vsftpd_login.db",
      owner => root, group => root, mode => 600,
      before => Service["vsftpd"],
      require => Package["vsftpd"];
    "/data/iso":
      ensure => directory,
      owner => vsftpd, group => vsftpd, mode => 777,
  }

  package { 
    "vsftpd":
    	ensure => present,
	    before => Service["vsftpd"];
    [
      "apache2-utils",
      "db4.6-util"
    ]
      : ensure => present;
  }

  service { 
    "vsftpd":
      enable => true,
      ensure  => running,
      pattern => '/vsftpd',
	    subscribe => File["/etc/vsftpd.conf"]
  }
}

class vsftpd::lamp {
  file {
    "/etc/pam.d/vsftpd":
      source => "${files_root}/vsftpd_1_0/vsftpd.pam",
      owner => root, group => root, mode => 600,
      before => Service["vsftpd"],
      require => Package["vsftpd"];
  }
  package { 
    "vsftpd":
    	ensure => present,
	    before => Service["vsftpd"];
    [
      "apache2-utils",
      "db4.6-util"
    ]
      : ensure => present;
  }

  service { 
    "vsftpd":
      enable => true,
      ensure  => running,
      pattern => '/vsftpd',
	    subscribe => File["/etc/vsftpd.conf"]
  }
}
