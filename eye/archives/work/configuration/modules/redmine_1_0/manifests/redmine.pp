class redmine_1_0::redmine {
  include monit
  include mysql_1_0::mysql
  package {
    "unicorn":
      ensure => present;
    "nginx":
      ensure => present;
  }
  file {
    "/etc/nginx/sites-enabled/redmine":
      owner => root, group => root, mode => 644,
      content => template("redmine_1_0/redmine.nginx.erb"),
      require => Package["nginx"];
    "/etc/nginx/sites-enabled/default":
      ensure => absent;
    "/var/run/redmine":
      owner => redmine, group => redmine, mode => 755,
      ensure => directory;
    "/var/log/redmine":
      owner => redmine, group => redmine, mode => 750,
      ensure => directory;
    "/etc/monitrc.d/redmine":
      owner => root, group => root, mode => 700,
      source => "${files_root}/redmine_1_0/monit_redmine",
      notify => Service["monit"],
      require => Package["monit"];
    "/var/log/redmine/default":
      owner => redmine, group => redmine, mode => 750,
      require => File["/var/log/redmine"],
      ensure => directory;
    "/opt/local/bin/fetch_repo.sh":
      owner => root, group => root, mode => 755,
      source => "${files_root}/redmine_1_0/fetch_repo.sh";
  }
  group {
    "redmine":
      ensure  => "present",
      gid     => "1008"
  }

  user {
    "redmine":
      ensure  => "present",
      uid     => "1008",
      gid     => "1008",
      comment => "redmine User",
      home    => "/srv/redmine",
      shell   => "/bin/bash",
      require => Group["redmine"]
  }
  mysql_1_0::mysql::mysql_db {
    "redmine":
      username => "redmine",
      password => "5jkfd2k0!";
  }
  cron {
    "fetch_repo":
       command => "/opt/local/bin/fetch_repo.sh",
       user => redmine,
       minute => '*/5';
  }

}
