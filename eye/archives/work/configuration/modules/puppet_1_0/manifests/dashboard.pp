class puppet_1_0::dashboard {
  include mysql_1_0::mysql

  package {
    "libjson-ruby1.8":
      require => Package["puppet-dashboard"],
      ensure => present;
    "puppet-dashboard":
      ensure => present;
    "unicorn":
      ensure => present;
  }

  file {
    "/etc/puppet-dashboard/unicorn.rb":
      owner => puppet, group => puppet, mode => 750,
      source => "${files_root}/puppet_1_0/unicorn.rb",
      require => Package["puppet-dashboard"];
    "/usr/share/puppet-dashboard/config/environment.rb":
      owner => puppet, group => puppet, mode => 750,
      source => "${files_root}/puppet_1_0/environment.rb",
      require => Package["puppet-dashboard"];
    "/etc/puppet-dashboard":
      owner => puppet, group => puppet, mode => 750,
      require => Package["puppet-dashboard"];
    "/etc/puppet-dashboard/database.yml":
      owner => puppet, group => puppet, mode => 750,
      source => "${files_root}/puppet_1_0/database.yml",
      require => Package["puppet-dashboard"];
    "/etc/monitrc.d/dashboard":
      owner => root, group => root, mode => 700,
      source => "${files_root}/puppet_1_0/monit_dashboard",
      notify => Service["monit"],
      require => [Package["monit"],Package["puppet-dashboard"]];
    "/usr/share/puppet-dashboard":
      owner => puppet, group => puppet,
      recurse => true,
      require => Package["puppet-dashboard"],
      ensure => directory;
    "/data/.htpasswd-dashboard":
      owner => root, group => root, mode => 755,
      require => File["${packages_dir}"],
      source => "${files_root}/puppet_1_0/htpasswd-dashboard";
  }

  mysql_1_0::mysql::mysql_db {
    "dashboard":
      username => "dashboard",
      password => "p0up33!";
  }

  apache_module {
    "proxy":
      ensure => present;
    "proxy_balancer":
      ensure => present;
    "proxy_http":
      ensure => present;
    "rewrite":
      ensure => present;
  }
}
