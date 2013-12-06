class erp::hector {
  package {
    [
      "build-essential","bison","openssl","libreadline5","libreadline5-dev","curl","zlib1g","zlib1g-dev","libssl-dev","libyaml-dev","libsqlite3-0","libsqlite3-dev","sqlite3","libxml2-dev","libxslt1-dev","autoconf","libc6-dev","libmysqlclient15-dev"
        ]: ensure => present;
  }

  package {
    "hector":
      ensure => present,
      require => [Exec["rvm-gem-install-unicorn"],Exec["rvm-gem-install-bunlder"],Package["libmysqlclient15-dev"]];
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

  exec {
    "rvm-install":
      command  => "su - hector -c 'bash < <( curl -s https://rvm.beginrescueend.com/install/rvm )' && touch /etc/rvm-hector-installed",
      timeout  => 3600,
      unless   => "test -f /etc/rvm-hector-installed",
      require  => [Package["curl"]];
    "rvm-install-ruby1.9":
      command => "su - hector -c 'rvm install ruby-1.9.2-p136' && touch /etc/rvm-hector-ruby-1.9.2-installed",
      timeout => 3600,
      unless   => "test -f /etc/rvm-hector-ruby-1.9.2-installed",
      require => [Package["build-essential"],Package["bison"],Package["openssl"],Package["libreadline5"],Package["libreadline5-dev"],Package["curl"],Package["git-core"],Package["zlib1g"],Package["zlib1g-dev"],Package["libssl-dev"],Package["libyaml-dev"],Package["libsqlite3-0"],Package["libsqlite3-dev"],Package["sqlite3"],Package["libxml2-dev"],Package["libxslt1-dev"],Package["autoconf"],Package["libc6-dev"],Exec["rvm-install"],File["/srv/hector/.bash_profile"]];
    "rvm-default-1.9.2":
      command => "su - hector -c 'rvm --default use 1.9.2-p136'",
      timeout => 3600,
      unless   => "su - hector -c 'rvm use | grep ruby-1.9.2'",
      require => Exec["rvm-install-ruby1.9"];
    "rvm-gem-install-bunlder":
      command => "su - hector -c 'gem install bundler -v 1.0.10'",
      timeout => 3600,
      unless => "su - hector -c 'gem list | grep bundler'",
      require => Exec["rvm-default-1.9.2"];
    "rvm-gem-install-unicorn":
      command => "su - hector -c 'gem install unicorn -v 3.6.0'",
      timeout => 3600,
      unless => "su - hector -c 'gem list | grep unicorn'",
      require => Exec["rvm-default-1.9.2"];
  }
  file {
    "/srv/hector":
      owner => hector, group => hector, mode => 750,
      ensure => directory;
    "/srv/hector/.bash_profile":
      owner => hector, group => hector, mode => 640,
      ensure => present,
      require => Exec["rvm-install"],
      source => "${files_root}/erp/bashrc";
    "/srv/hector/config/unicorn.rb":
      owner => hector, group => hector, mode => 644,
      source => "${files_root}/erp/hector_unicorn",
      require => Package["hector"];
    "/etc/monitrc.d/hector":
      owner => root, group => root, mode => 700,
      source => "${files_root}/erp/monit_hector",
      notify => Service["monit"],
      require => [Package["monit"],Package["hector"],File["/srv/hector/config/unicorn.rb"]];
    "/etc/nginx/sites-enabled/hector":
      owner => root, group => root, mode => 700,
      source => "${files_root}/erp/nginx_hector";
    "/etc/nginx/hector.htpasswd":
      owner => www-data, group => www-data, mode => 644,
      source => "${files_root}/erp/nginx_htpasswd_hector"; # login: hector / passwd : dKSc7gv2
  }
}
