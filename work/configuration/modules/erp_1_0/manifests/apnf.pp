class erp_1_0::apnf_ftp (
  $operator_ftp_user,
  $operator_ftp_passwd
) {
  include vsftpd::lamp
  # Param ftp
  file {
    "/etc/vsftpd.conf":
      owner => root, group => root, mode => 600,
      content => template("erp_1_0/apnf/vsftpd.conf.erb"),
      before => Service["vsftpd"],
      require => Package["vsftpd"];
    "/etc/vsftpd_login.db.txt":
      content => template("erp_1_0/apnf/vsftpd_login.db.txt.erb"),
      owner => root, group => root, mode => 600,
      before => Service["vsftpd"],
      require => Package["db4.6-util","vsftpd"];
  }
  exec {
    "create_ftp_usrdb":
      command => "db4.6_load -T -t hash -f /etc/vsftpd_login.db.txt /etc/vsftpd_login.db",
      require => File["/etc/vsftpd_login.db.txt"]
  }
  file {
    "/data/ftp":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => [File["/data"],Package["vsftpd"]];
    "/data/ftp/prod":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => File["/data/ftp"];
    "/data/ftp/prod/BDC":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => File["/data/ftp/prod"];
    "/data/ftp/prod/MIT":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => File["/data/ftp/prod"];
    "/data/ftp/preprod":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => File["/data/ftp"];
    "/data/ftp/preprod/BDC":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => File["/data/ftp/preprod"];
    "/data/ftp/preprod/MIT":
      owner => ftp, group => ftp, mode => 775,
      ensure => directory,
      require => File["/data/ftp/preprod"];
  }
  case $apnf_ftp_create_lv {
    true : {
      file {
        "/opt/local/bin/create-apnf-ftp-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/erp_1_0/create-apnf-ftp-lv";
      }

      exec { "Create APNF FTP LV":
        require => File["/opt/local/bin/create-apnf-ftp-lv"],
        unless => "lvdisplay /dev/data/ftp",
        command => "/opt/local/bin/create-apnf-ftp-lv",
        before => Package["vsftpd"]
      }
    }
  }
}

class erp_1_0::apnf_ipsec {
  host_file {
    "/etc/ipsec.conf":;
    "/etc/ipsec.secrets":;
  }
  package {
    "strongswan": ensure => present;
  }
  service { "ipsec":
    ensure => running,
    require => Package["strongswan"],
    subscribe => File["/etc/ipsec.conf"],
  }
}

class erp_1_0::apnf (
  $apnf_ftp_host = "127.0.0.1",
  $apnf_ftp_port = "2121",
  $apnf_ftp_user,
  $apnf_ftp_passwd,
  $operator_ftp_host = "127.0.0.1",
  $operator_ftp_user,
  $operator_ftp_passwd,
  $environment = "preproduction",
  $iface_si,
  $mongo_ip
) {
  group {
    "apnf":
      ensure  => present,
      gid     => "1009"
  }

  package {
    "apnf": ensure => present;
  }

  user {
    "apnf":
      ensure  => present,
      uid     => "1009",
      gid     => "1009",
      comment => "APNF User",
      home    => "/srv/apnf",
      shell   => "/bin/bash",
      require => Group["apnf"]
  }
 
  file {
    "/srv/apnf":
      owner => apnf, group => apnf, mode => 750,
      require => User["apnf"],
      ensure => directory;
    "/srv/apnf/tmp/rx":
      owner => apnf, group => apnf, mode => 750,
      require => User["apnf"],
      ensure => directory;
    "/srv/apnf/tmp/tx":
      owner => apnf, group => apnf, mode => 750,
      require => User["apnf"],
      ensure => directory;
    "/srv/apnf/.bashrc":
      owner => apnf, group => apnf, mode => 644,
      ensure => present,
      require => File["/srv/apnf"], 
      content => "rvm use 1.9.2-p180";
    "/srv/apnf/config/unicorn.rb":
      owner => apnf, group => apnf, mode => 644,
      content => template("erp_1_0/apnf/unicorn.erb"),
      require => Package["apnf"];
    "/etc/monitrc.d/apnf":
      owner => root, group => root, mode => 700,
      content => template("erp_1_0/apnf/monit.erb"),
      notify => Service["monit"],
      require => [Package["monit"],File["/srv/apnf/config/unicorn.rb"]];
    "/etc/monitrc.d/apnfd":
      owner => root, group => root, mode => 700,
      content => template("erp_1_0/apnf/monit_apnfd.erb"),
      notify => Service["monit"],
      require => [Package["monit", "apnf"]];
    "/etc/apnf/application.yml":
      owner => root, group => root, mode => 744,
      content => template("erp_1_0/apnf/application.yml.erb"),
      require => Package["apnf"];
    "/etc/apnf/mongoid.yml":
      owner => root, group => root, mode => 744,
      content => template("erp_1_0/apnf/mongoid.yml.erb"),
      require => Package["apnf"];
  }
  
  include rvm::system
  if $rvm_installed == "true" {
    rvm_system_ruby {
      'ruby-1.9.2-p180':
        ensure => 'present',
        default_use => false;
    }
    rvm::system_user { apnf: ; }
  }
  $mongo_bind_address= "127.0.0.1"
  include erp::mongodb-base  
}
