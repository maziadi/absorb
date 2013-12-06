define erp_1_0::rails_app (
  $environment = "preproduction",
  $ruby_version = "1.9.3-p194",
  $app_name = $title,
  $unicorn_workers = "2",
  $unicorn_timeout = "30",
  $unicorn_sql = false,
  $bind_address = "127.0.0.1",
  $bind_port = "3001",
  $uid, $gid,
  $unicorn_start = true,
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
    if defined(Rvm_system_ruby["${ruby_version}"]) {
      alert ("jruby already defined")
    } 
    else {
      rvm_system_ruby {
        "${ruby_version}":
          ensure => 'present',
          default_use => false;
      }
    }
    rvm::system_user { $app_name: ; }
  }
  if defined(Package["rubygems"]) {
    alert ("rubygems already defined")
  }
  else {
    package {
      "rubygems" : ensure => present;
    } 
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
        content => template("erp_1_0/rails_app/unicorn.rb.erb"),
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
      target => "/etc/si/configuration_si.yml",
      require => Package["${app_name}"],
      ensure => link;
#      owner => $app_name, group => $app_name, mode => 640,
#      content => template("erp_1_0/rails_app/configuration_si.yml.erb"),
#      require => [Package["${app_name}"],User["${app_name}"],Group["${app_name}"]];
  }
  if defined(File["/usr/bin/cmdwrapper"]) {
    alert ("")
  } else {
    file {
      "/usr/bin/cmdwrapper":
        owner => 'root', group => 'root', mode => 650,
        content => template("erp_1_0/rails_app/cmdwrapper.sh.erb");
    }
  }
}
