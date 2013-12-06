class erp::taxman {
  case $cdrlog_create_lv { '': { $cdrlog_create_lv = false } }
  case $consumer_number { '': { $consumer_number = 1 } }
  case $cdrlog_vg_name { '': { $cdrlog_vg_name = "data" } }
  case $webserver_taxman { '': { $webserver_taxman = false } }
  case $taxman_env { '': { $taxman_env = "development" } }
  case $allowing_hosts { '': { $allowing_hosts = ["127.0.0.1"] } }
  case $unicorn_bind_address { '': { $unicorn_bind_address= "127.0.0.1" }}
  case $mongo_bind_address { '': { $mongo_bind_address= "127.0.0.1" }}
  $mongo_replica_set = "taxman"
  include erp::mongodb-base
  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email
  package {
    [
      "build-essential",
      "bison",
      "openssl",
      "libreadline6",
      "libreadline6-dev",
      "curl",
      "git-core",
      "zlib1g",
      "zlib1g-dev",
      "libssl-dev",
      "libyaml-dev",
      "libsqlite3-0",
      "libsqlite3-dev",
      "sqlite3",
      "libxml2-dev",
      "libxslt-dev",
      "autoconf",
      "libc6-dev"
        ]: ensure => present;
  }

  package {
    "taxman":
      ensure => present,
      require => [Exec["rvm-gem-install-daemons"],Exec["rvm-gem-install-bunlder"]];
  }
  case $cdrlog_create_lv {
    true : {
      file {
        "/opt/local/bin/create-cdrlog-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/erp/create-cdrlog-lv";
      }

      exec { "Create cdrlog LV":
        require => File["/opt/local/bin/create-cdrlog-lv"],
        unless => "lvdisplay /dev/${cdrlog_vg_name}/data",
        command => "/opt/local/bin/create-cdrlog-lv",
        before => Package["taxman"]
      }
    }
  }
  group {
    "taxman":
      ensure  => "present",
      gid     => "1005"
  }

  user {
    "taxman":
      ensure  => "present",
      uid     => "1005",
      gid     => "1005",
      comment => "Taxman User",
      home    => "/srv/taxman",
      shell   => "/bin/bash",
      require => Group["taxman"]
  }

  exec {
    "rvm-install":
      command  => "su - taxman -c 'bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)' && touch /etc/rvm-taxman-installed",
      timeout  => 3600,
      unless   => "test -f /etc/rvm-taxman-installed",
      require  => [Package["curl"]];
    "rvm-install-ruby1.9":
      command => "su - taxman -c 'rvm install ruby-1.9.2-p180' && touch /etc/rvm-taxman-ruby-1.9.2-installed",
      timeout => 3600,
      unless   => "test -f /etc/rvm-taxman-ruby-1.9.2-installed",
      require => [Package["build-essential"],Package["bison"],Package["openssl"],Package["libreadline6"],Package["libreadline6-dev"],Package["curl"],Package["git-core"],Package["zlib1g"],Package["zlib1g-dev"],Package["libssl-dev"],Package["libyaml-dev"],Package["libsqlite3-0"],Package["libsqlite3-dev"],Package["sqlite3"],Package["libxml2-dev"],Package["libxslt-dev"],Package["autoconf"],Package["libc6-dev"],Exec["rvm-install"]];
    "rvm-default-1.9.2":
      command => "su - taxman -c 'rvm --default use 1.9.2-p180'",
      timeout => 3600,
      unless   => "su - taxman -c 'rvm use | grep ruby-1.9.2'",
      require => Exec["rvm-install-ruby1.9"];
    "rvm-gem-install-bunlder":
      command => "su - taxman -c 'gem install bundler -v 1.0.10'",
      timeout => 3600,
      unless => "su - taxman -c 'gem list | grep bundler'",
      require => Exec["rvm-default-1.9.2"];
    "rvm-gem-install-daemons":
      command => "su - taxman -c 'gem install daemons -v 1.1.0'",
      timeout => 3600,
      unless => "su - taxman -c 'gem list | grep daemons'",
      require => Exec["rvm-default-1.9.2"];
  }
  file {
    "/srv/taxman":
      owner => taxman, group => taxman, mode => 750,
      ensure => directory;
    "/srv/taxman/.bashrc":
      owner => taxman, group => taxman, mode => 640,
      ensure => present,
      require => Exec["rvm-install"],
      content => template('erp/bashrc_taxman.erb');
    "/etc/monitrc.d/taxman":
      owner => root, group => root, mode => 700,
      content => template('erp/monit_taxman.erb'),
      notify => Service["monit"],
      require => [Package["monit"],Package["taxman"]];
    "/etc/monitrc.d/mongodb-arbiter":
      owner => root, group => root, mode => 700,
      source => "${files_root}/erp/monit_mongodb-arbiter",
      notify => Service["monit"],
      require => [Package["monit"],Package["mongodb"],File["/var/lib/mongodb-arbiter"]];
    "/var/lib/mongodb-arbiter":
      owner => mongodb, group => mongodb, mode => 750,
      ensure => directory;
  }
  host_file {
      "/etc/taxman/configuration.yaml": mode => 755;
      "/etc/taxman/mongoid.yml": mode => 755;
      "/etc/default/cdr-archiver-cbv1": mode => 644;
      "/etc/default/cdr-archiver-cbv2": mode => 644;
  }

  file {
    "/data/accounting":
      owner => taxman, group => taxman, mode => 755,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/data/archives":
      owner => taxman, group => taxman, mode => 755,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/data/vno_journals":
      owner => taxman, group => taxman, mode => 755,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/data/csv_reports":
      owner => taxman, group => taxman, mode => 755,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/data/cdr_archiver":
      owner => taxman, group => taxman, mode => 750,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/data/cdr_archives":
      owner => taxman, group => taxman, mode => 750,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/var/run/taxman":
      owner => taxman, group => taxman, mode => 755,
      ensure => directory;
  }

  file {
    "/var/lib/cdr-archiver":
      ensure => link,
      target => "/data/cdr_archiver";
  }

  package {
    ["cdr-archiver-cbv1", "cdr-archiver-cbv2"]:
      ensure => present,
      require => File["/var/lib/cdr-archiver"];
  }
      
  case $webserver_taxman {
    true : {
      file {
        "/etc/taxman/unicorn.rb":
          owner => root, group => root, mode => 644,
          content => template('erp/unicorn.rb.erb'),
          require => [Package["taxman"], File["/var/log/taxman"],File["/var/run/taxman"]];
        "/srv/taxman/config/unicorn.rb":
          ensure => link,
          require => File["/etc/taxman/unicorn.rb"],
          target => "/etc/taxman/unicorn.rb";
        "/etc/nginx/sites-enabled/taxman":
          owner => root, group => root, mode => 755,
          content => template('erp/taxman.nginx.erb'),
          require => Package["nginx"];
        "/etc/monitrc.d/unicorn":
          owner => root, group => root, mode => 700,
          content => template('erp/monit_unicorn.erb'),
          notify => Service["monit"],
          require => [Package["monit"],Exec["rvm-gem-install-unicorn"]];
        # unicorn log
        "/var/log/taxman":
          owner => taxman, group => taxman, mode => 750,
          ensure => directory;
        "/etc/logrotate.d/unicorn-taxman":
          owner => root, group => root, mode => 644,
          source => "${files_root}/erp/unicorn-taxman-logrotate",
          notify => Service["monit"],
          require => [Package["monit"],Exec["rvm-gem-install-unicorn"]];
        "/etc/monitrc.d/delayed_job_taxman":
          owner => root, group => root, mode => 700,
          content => template('erp/monit_delayed_job_taxman.erb'),
          notify => Service["monit"],
          require => [Package["monit"],Package["taxman"]];
      }
      exec {
        "rvm-gem-install-unicorn":
          command => "su - taxman -c 'gem install unicorn -v 3.6.0'",
          timeout => 3600,
          unless => "su - taxman -c 'gem list | grep unicorn'",
          require => [Exec["rvm-default-1.9.2"],File["/etc/taxman/unicorn.rb"]];
      }
      package {
        "nginx":
          ensure => present;
      }
    }
  }
}
