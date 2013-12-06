class erp::sso {

  package {
    "unicorn" : ensure => present;
  }

  package {
    "cas":
      require => [File["/srv/cas"],Package["unicorn"]],
      ensure => present;
  }

  group {
    "cas":
      ensure  => present,
      gid     => "1007"
  }

  user {
    "cas":
      ensure  => present,
      uid     => "1007",
      gid     => "1007",
      comment => "cas User",
      home    => "/srv/cas",
      shell   => "/bin/bash",
      require => Group["cas"]
  }
  file {
    "/srv/cas":
      owner => cas, group => cas, mode => 750,
      require => [User["cas"],Group["cas"]],
      ensure => directory;
    "/srv/cas/config/unicorn.rb":
      owner => cas, group => cas, mode => 644,
      source => "${files_root}/erp/cas_unicorn",
      require => [Package["cas"]];
    "/etc/monitrc.d/cas":
      owner => root, group => root, mode => 700,
      source => "${files_root}/erp/monit_cas",
      notify => Service["monit"],
      require => [Package["monit"],Package["cas"],File["/srv/cas/config/unicorn.rb"]];
  }
}
