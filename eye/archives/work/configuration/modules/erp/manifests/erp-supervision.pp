class erp::supervision {

  include rvm::system
  if $rvm_installed == "true" {
    rvm_system_ruby {
      'ruby-1.9.2-p180':
        ensure => 'present',
        default_use => false;
    }
    rvm::system_user { supervision: ; }
  }

  $mongo_bind_address= "127.0.0.1"

  include erp::mongodb-base  
  include nginx

  package {
    "supervision":
      require => [File["/srv/supervision"]],
      ensure => present;
  }

  group {
    "supervision":
      ensure  => present,
      gid     => "1010"
  }

  user {
    "supervision":
      ensure  => present,
      uid     => "1010",
      gid     => "1010",
      comment => "supervision User",
      home    => "/srv/supervision",
      shell   => "/bin/bash",
      require => Group["supervision"]
  }
  file {
    "/srv/supervision":
      owner => supervision, group => supervision, mode => 755,
      require => [User["supervision"],Group["supervision"]],
      ensure => directory;
    "/srv/supervision/.bashrc":
      owner => supervision, group => supervision, mode => 644,
      ensure => present,
      require => File["/srv/supervision"], 
      content => "export RAILS_ENV=production\nrvm use 1.9.2-p180";
    "/etc/logrotate.d/supervision":
      owner => root, group => root, mode => 644,
      source => "${files_root}/erp/logrotate_supervision",
      require => [Package["supervision"]];
    "/etc/supervision/unicorn.rb":
      owner => supervision, group => supervision, mode => 644,
      source => "${files_root}/erp/unicorn_supervision",
      require => [Package["supervision"]];
    "/etc/monitrc.d/supervision":
      owner => root, group => root, mode => 700,
      source => "${files_root}/erp/monit_supervision",
      notify => Service["monit"],
      require => [Package["monit"],Package["supervision"],File["/etc/supervision/unicorn.rb"]];
    "/etc/monitrc.d/supervision_consumer":
      owner => root, group => root, mode => 700,
      source => "${files_root}/erp/monit_supervision_consumer",
      notify => Service["monit"],
      require => [Package["monit"],Package["supervision"],File["/etc/supervision/unicorn.rb"]];
  }
}
