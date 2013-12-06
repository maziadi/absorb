class erp_1_0::hector (
  $environment = "preproduction",
  $db_user, $db_passwd, $db_host, $db_name, $iface_si
) {

  package {
    "hector":
      ensure => present,
      require => File["/srv/hector"];
  }

  group {
    "hector":
      ensure  => present,
      gid     => "1006"
  }

  user {
    "hector":
      ensure  => present,
      uid     => "1006",
      gid     => "1006",
      comment => "Hector User",
      home    => "/srv/hector",
      shell   => "/bin/bash",
      require => Group["hector"]
  }

  include rvm::system
  if $rvm_installed == "true" {
    rvm_system_ruby {
      'ruby-1.9.2-p180':
        ensure => 'present',
        default_use => false;
    }
    rvm::system_user { hector: ; }
  }

  file {
    "/srv/hector":
      owner => hector, group => hector, mode => 750,
      ensure => directory;
    "/srv/hector/.bash_profile":
      owner => hector, group => hector, mode => 640,
      ensure => present,
      content => template("erp_1_0/hector/bashrc.erb");
    "/srv/hector/.bashrc":
      owner => hector, group => hector, mode => 644,
      ensure => present,
      require => File["/srv/hector"], 
      content => "export RAILS_ENV=${environment}\nrvm use 1.9.2-p180";
    "/srv/hector/config/unicorn.rb":
      owner => hector, group => hector, mode => 644,
      content => template("erp_1_0/hector/unicorn.erb"),
      require => Package["hector"];
    "/etc/monitrc.d/hector":
      owner => root, group => root, mode => 700,
      content => template("erp_1_0/hector/monit.erb"),
      notify => Service["monit"],
      require => [Package["monit"],File["/srv/hector/config/unicorn.rb"]];
    "/etc/hector/database.yml":
      owner =>"hector", group => "hector", mode => 640,
      content => template("erp_1_0/hector/database.yml.erb"),
      require => [Package["hector"]];
    "/etc/hector/configuration.yml":
      owner =>"hector", group => "hector", mode => 640,
      source => "$files_root/erp_1_0/hector/configuration.yml",
      require => [Package["hector"]];
  }
}
