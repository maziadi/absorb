class erp_1_0::clockwork (
$clockwork_get_ftp_host , $clockwork_get_ftp_username , $clockwork_get_ftp_password , $clockwork_get_ftp_repository = '' , 
$clockwork_put_ftp_host , $clockwork_put_ftp_username , $clockwork_put_ftp_password , $clockwork_put_ftp_repository ,  
$clockwork_get_amq_host , $clockwork_get_amq_username , $clockwork_get_amq_password , $clockwork_get_amq_queue ,
$clockwork_put_amq_host , $clockwork_put_amq_username , $clockwork_put_amq_password , $clockwork_put_amq_queue ,
$clockwork_email_login , $clockwork_email_password , $clockwork_email_report , $apnf_ip 
)
{

  group {
    "clockwork":
      ensure  => present,
      gid     => "1008"
  }

  user {
    "clockwork":
      ensure  => present,
      uid     => "1008",
      gid     => "1008",
      comment => "Clockwork User",
      home    => "/srv/clockwork",
      shell   => "/bin/bash",
      require => Group["clockwork"]
  }

  exec {
    "reload_gpg":
      command => "gpg --import /srv/clockwork/config/alpha.gpg || true",
      cwd => "/srv/clockwork",
      user => "clockwork",
      refreshonly => true,
      require => [Package["gnupg"],File["/srv/clockwork/config/alpha.gpg"]];
  }

  package {
    "gnupg":
      ensure => present;
    "rubygems":
      ensure => present;
    "ncftp":
      ensure => present;
    "clockwork":
      require => [File["/srv/clockwork"]],
      ensure => present;
  }

  file {
    "/srv/clockwork":
      owner => clockwork, group => clockwork, mode => 750,
      require => [User["clockwork"],Group["clockwork"]],
      ensure => directory;
    "/srv/clockwork/.gnupg":
      owner => clockwork, group => clockwork, mode => 700,
      ensure => directory,
      require => [Package["gnupg"],File["/srv/clockwork"]];
    "/srv/clockwork/config/alpha.gpg":
      owner => clockwork, group => clockwork, mode => 600,
      source => "${files_root}/erp_1_0/clockwork/alpha.gpg",
      require => [Package["clockwork"],File["/srv/clockwork/.gnupg"]];
    "/etc/logrotate.d/clockwork":
      owner => root, group => root, mode => 644,
      source => "${files_root}/erp_1_0/clockwork/logrotate",
      require => [Package["clockwork"]];
    "/etc/clockwork/application.yml":
      owner => clockwork, group => clockwork, mode => 644,
      ensure => present,
      content => template("erp_1_0/clockwork/application.yml.erb"),
      require => [Package["clockwork"]];
  }
}
