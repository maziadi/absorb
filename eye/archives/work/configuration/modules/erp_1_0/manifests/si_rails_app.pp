class erp_1_0::si_rails_app (
  $environment = "preproduction",
  $ruby_version = "1.9.3-p194",
  $app_name,
  $unicorn_workers = "2",
  $unicorn_timeout = "30",
  $unicorn_sql = false,
  $bind_address = "127.0.0.1",
  $bind_port = "3001",
  $uid, $gid,
  $unicorn_start = true,
  $erp_ip,
  $erp_port,
  $anderson_ip,
  $anderson_port,
  $taxman_ip,
  $taxman_port,
  $hector_ip,
  $hector_port,
  $pouss_mouss_ip,
  $pouss_mouss_port,
  $uixiv_ip,
  $uixiv_port,
  $drive_ip,
  $drive_port,
  $apnf_ip,
  $apnf_port,
  $killbill_ip,
  $killbill_port,
  $amq_si_host,
  $amq_si_user,
  $amq_si_passwd,
  $amq_erp_host,
  $amq_erp_user,
  $amq_erp_passwd,
  $profile = "",
) {
  include monit

  package {
    "rubygems" : ensure => present;
  }

  package {
    $app_name:
      require => File["/srv/${app_name}"],
      ensure => present;
  }

  group {
    $app_name:
      ensure  => present,
      gid     => $gid
  }

  user {
    $app_name:
      ensure  => present,
      uid     => $uid,
      gid     => $gid,
      comment => "${app_name} user",
      home    => "/srv/${app_name}",
      shell   => "/bin/bash",
      require => Group[$app_name]
  }

  include rvm::system
  if $rvm_installed == "true" {
    rvm_system_ruby {
      "${ruby_version}":
        ensure => 'present',
        default_use => false;
    }
    rvm::system_user { $app_name: ; }
  }

  if $unicorn_start {
    file{
      "/etc/monitrc.d/${app_name}":
        owner => root, group => root, mode => 700,
        content => template("erp_1_0/si_rails_app/monit.erb"),
        notify => Service["monit"],
        require => [Package["monit"],Package["${app_name}"]];
      "/srv/${app_name}/config/unicorn.rb":
        owner => $app_name, group => $app_name, mode => 640,
        content => template("erp_1_0/si_rails_app/unicorn.rb.erb"),
        require => [Package["${app_name}"]];
    }
  }
  file {
    "/srv/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"],File["/var/run/${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/.bash_profile":
      owner => $app_name, group => $app_name, mode => 640,
      ensure => present,
      content => template("erp_1_0/erp/bash_profile.erb"),
      require => [File["/srv/${app_name}"]];
    "/srv/${app_name}/.bashrc":
      owner => $app_name, group => $app_name, mode => 644,
      ensure => present,
      require => File["/srv/${app_name}"],
      content => "export RAILS_ENV=${environment}\nrvm use ${ruby_version}\nexport LD_LIBRARY_PATH='/usr/local/rvm/rubies/${ruby_version}/lib/'\n${profile}";
    "/var/run/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/config/configuration_si.yml":
      owner => $app_name, group => $app_name, mode => 640,
      content => template("erp_1_0/si_rails_app/configuration_si.yml.erb"),
      require => [Package["${app_name}"],User["${app_name}"],Group["${app_name}"]];
    "/usr/bin/cmdwrapper":
      owner => 'root', group => 'root', mode => 650,
      content => template("erp_1_0/si_rails_app/cmdwrapper.sh.erb");
  }
}
class erp_1_0::si_rails_app_2 (
  $environment = "preproduction",
  $ruby_version = "1.9.3-p194",
  $app_name,
  $unicorn_workers = "2",
  $unicorn_timeout = "30",
  $unicorn_sql = false,
  $bind_address = "127.0.0.1",
  $bind_port = "3001",
  $uid, $gid,
  $unicorn_start = true,
  $erp_ip,
  $erp_port,
  $anderson_ip,
  $anderson_port,
  $taxman_ip,
  $taxman_port,
  $hector_ip,
  $hector_port,
  $pouss_mouss_ip,
  $pouss_mouss_port,
  $uixiv_ip,
  $uixiv_port,
  $drive_ip,
  $drive_port,
  $apnf_ip,
  $apnf_port,
  $killbill_ip,
  $killbill_port,
  $amq_si_host,
  $amq_si_user,
  $amq_si_passwd,
  $amq_erp_host,
  $amq_erp_user,
  $amq_erp_passwd,
  $profile = "",
) {
  include monit


  package {
    $app_name:
      require => File["/srv/${app_name}"],
      ensure => present;
  }

  group {
    $app_name:
      ensure  => present,
      gid     => $gid
  }

  user {
    $app_name:
      ensure  => present,
      uid     => $uid,
      gid     => $gid,
      comment => "${app_name} user",
      home    => "/srv/${app_name}",
      shell   => "/bin/bash",
      require => Group[$app_name]
  }

  include rvm::system
  if $rvm_installed == "true" {
    rvm_system_ruby {
      "${ruby_version}":
        ensure => 'present',
        default_use => false;
    }
    rvm::system_user { $app_name: ; }
  }

  if $unicorn_start {
    file{
      "/etc/monitrc.d/${app_name}":
        owner => root, group => root, mode => 700,
        content => template("erp_1_0/si_rails_app/monit.erb"),
        notify => Service["monit"],
        require => [Package["monit"],Package["${app_name}"]];
      "/srv/${app_name}/config/unicorn.rb":
        owner => $app_name, group => $app_name, mode => 640,
        content => template("erp_1_0/si_rails_app/unicorn.rb.erb"),
        require => [Package["${app_name}"]];
    }
  }
  file {
    "/srv/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"],File["/var/run/${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/.bash_profile":
      owner => $app_name, group => $app_name, mode => 640,
      ensure => present,
      content => template("erp_1_0/erp/bash_profile.erb"),
      require => [File["/srv/${app_name}"]];
    "/srv/${app_name}/.bashrc":
      owner => $app_name, group => $app_name, mode => 644,
      ensure => present,
      require => File["/srv/${app_name}"],
      content => "export RAILS_ENV=${environment}\nrvm use ${ruby_version}\nexport LD_LIBRARY_PATH='/usr/local/rvm/rubies/${ruby_version}/lib/'\n${profile}";
    "/var/run/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/config/configuration_si.yml":
      owner => $app_name, group => $app_name, mode => 640,
      content => template("erp_1_0/si_rails_app/configuration_si.yml.erb"),
      require => [Package["${app_name}"],User["${app_name}"],Group["${app_name}"]];
  }
}
class erp_1_0::si_rails_app_3 (
  $environment = "preproduction",
  $ruby_version = "1.9.3-p194",
  $app_name,
  $unicorn_workers = "2",
  $unicorn_timeout = "30",
  $unicorn_sql = false,
  $bind_address = "127.0.0.1",
  $bind_port = "3001",
  $uid, $gid,
  $unicorn_start = true,
  $erp_ip,
  $erp_port,
  $anderson_ip,
  $anderson_port,
  $taxman_ip,
  $taxman_port,
  $hector_ip,
  $hector_port,
  $pouss_mouss_ip,
  $pouss_mouss_port,
  $uixiv_ip,
  $uixiv_port,
  $drive_ip,
  $drive_port,
  $apnf_ip,
  $apnf_port,
  $killbill_ip,
  $killbill_port,
  $amq_si_host,
  $amq_si_user,
  $amq_si_passwd,
  $amq_erp_host,
  $amq_erp_user,
  $amq_erp_passwd,
  $profile = "",
) {

  package {
    $app_name:
      require => File["/srv/${app_name}"],
      ensure => present;
  }

  group {
    $app_name:
      ensure  => present,
      gid     => $gid
  }

  user {
    $app_name:
      ensure  => present,
      uid     => $uid,
      gid     => $gid,
      comment => "${app_name} user",
      home    => "/srv/${app_name}",
      shell   => "/bin/bash",
      require => Group[$app_name]
  }

  include rvm::system
  if $rvm_installed == "true" {
    rvm_system_ruby {
      "${ruby_version}":
        ensure => 'present',
        default_use => false;
    }
    rvm::system_user { $app_name: ; }
  }

  if $unicorn_start {
    monit_1_0::monit::monit_file {
      "si":
         filename => "${app_name}",
         requires => Package["${app_name}"];
    }
    file{
      "/srv/${app_name}/config/unicorn.rb":
        owner => $app_name, group => $app_name, mode => 640,
        content => template("erp_1_0/si_rails_app/unicorn.rb.erb"),
        require => [Package["${app_name}"]];
    }
  }
  file {
    "/srv/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"],File["/var/run/${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/.bash_profile":
      owner => $app_name, group => $app_name, mode => 640,
      ensure => present,
      content => template("erp_1_0/erp/bash_profile.erb"),
      require => [File["/srv/${app_name}"]];
    "/srv/${app_name}/.bashrc":
      owner => $app_name, group => $app_name, mode => 644,
      ensure => present,
      require => File["/srv/${app_name}"],
      content => "export RAILS_ENV=${environment}\nrvm use ${ruby_version}\nexport LD_LIBRARY_PATH='/usr/local/rvm/rubies/${ruby_version}/lib/'\n${profile}";
    "/var/run/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/config/configuration_si.yml":
      owner => $app_name, group => $app_name, mode => 640,
      content => template("erp_1_0/si_rails_app/configuration_si.yml.erb"),
      require => [Package["${app_name}"],User["${app_name}"],Group["${app_name}"]];
     "/usr/bin/cmdwrapper":
      owner => 'root', group => 'root', mode => 650,
      content => template("erp_1_0/si_rails_app/cmdwrapper.sh.erb");
  }
}
class erp_1_0::si_rails_app_4 (
  $environment = "preproduction",
  $ruby_version = "1.9.3-p194",
  $app_name,
  $unicorn_workers = "2",
  $unicorn_timeout = "30",
  $unicorn_sql = false,
  $bind_address = "127.0.0.1",
  $bind_port = "3001",
  $uid, $gid,
  $unicorn_start = true,
  $erp_ip,
  $erp_port,
  $anderson_ip,
  $anderson_port,
  $taxman_ip,
  $taxman_port,
  $hector_ip,
  $hector_port,
  $pouss_mouss_ip,
  $pouss_mouss_port,
  $uixiv_ip,
  $uixiv_port,
  $drive_ip,
  $drive_port,
  $apnf_ip,
  $apnf_port,
  $killbill_ip,
  $killbill_port,
  $amq_si_host,
  $amq_si_user,
  $amq_si_passwd,
  $amq_erp_host,
  $amq_erp_user,
  $amq_erp_passwd,
  $profile = "",
) {

  package {
    $app_name:
      require => File["/srv/${app_name}"],
      ensure => present;
  }

  group {
    $app_name:
      ensure  => present,
      gid     => $gid
  }

  user {
    $app_name:
      ensure  => present,
      uid     => $uid,
      gid     => $gid,
      comment => "${app_name} user",
      home    => "/srv/${app_name}",
      shell   => "/bin/bash",
      require => Group[$app_name]
  }

  include rvm::system
  if $rvm_installed == "true" {
   if ! Rvm_system_ruby["ruby_version"]{
    rvm_system_ruby {
      "${ruby_version}":
        ensure => 'present',
        default_use => false;
    }
   }
    rvm::system_user { $app_name: ; }
  }

  if $unicorn_start {
    monit_1_0::monit::monit_file {
      "si":
         filename => "${app_name}",
         requires => Package["${app_name}"];
    }
    file{
      "/srv/${app_name}/config/unicorn.rb":
        owner => $app_name, group => $app_name, mode => 640,
        content => template("erp_1_0/si_rails_app/unicorn.rb.erb"),
        require => [Package["${app_name}"]];
    }
  }
  file {
    "/srv/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"],File["/var/run/${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/.bash_profile":
      owner => $app_name, group => $app_name, mode => 640,
      ensure => present,
      content => template("erp_1_0/erp/bash_profile.erb"),
      require => [File["/srv/${app_name}"]];
    "/srv/${app_name}/.bashrc":
      owner => $app_name, group => $app_name, mode => 644,
      ensure => present,
      require => File["/srv/${app_name}"],
      content => "export RAILS_ENV=${environment}\nrvm use ${ruby_version}\nexport LD_LIBRARY_PATH='/usr/local/rvm/rubies/${ruby_version}/lib/'\n${profile}";
    "/var/run/${app_name}":
      owner => $app_name, group => $app_name, mode => 750,
      require => [User["${app_name}"],Group["${app_name}"]],
      ensure => directory;
    "/srv/${app_name}/config/configuration_si.yml":
      owner => $app_name, group => $app_name, mode => 640,
      content => template("erp_1_0/si_rails_app/configuration_si.yml.erb"),
      require => [Package["${app_name}"],User["${app_name}"],Group["${app_name}"]];
  }
}
