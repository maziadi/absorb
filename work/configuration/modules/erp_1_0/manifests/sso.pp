class erp_1_0::sso (
  $environment = "preproduction",
  $db_host, $db_user, $db_passwd, $db_name, $db_auth_name, $iface_si
) {
  include monit

  package {
    "unicorn" : ensure => present;
    "rubygems" : ensure => present;
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
      content => template("erp_1_0/cas/unicorn.erb"),
      require => [Package["cas"]];
    "/etc/monitrc.d/cas":
      owner => root, group => root, mode => 700,
      content => template("erp_1_0/cas/monit.erb"),
      notify => Service["monit"],
      require => [Package["monit"],Package["cas"],File["/srv/cas/config/unicorn.rb"]];
    "/etc/cas/config.yml":
      owner =>"root", group => "root", mode => 644,
      content => template("erp_1_0/cas/config.yml.erb"),
      require => [Package["cas"]];
  }
}
