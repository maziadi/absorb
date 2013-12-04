class erp_1_0::obao (
  $environment = "preproduction",
  $db_host, $db_name, $cert_passwd,
) {
  $profile = $environment ? {
    "preproduction" => "export OBAO_MOCK=true",
    default => "",
  }
  if ! Package["libmysqlclient-dev"] {
    package {
      [
        "libmysqlclient-dev",
      ]: ensure => present;
    }
  }

  erp_1_0::rails_app {
    "obao":
      uid     => "1013",
      gid     => "1013",
      environment => $environment,
      ruby_version => "ruby-1.9.3-p194",
      unicorn_start => false,
      profile => $profile;
  }

  monit_1_0::monit::monit_file {
    "obao":
       requires => Package["obao"]
  }

  file {
    "/etc/obao/application.yml":
      owner =>"root", group => "root", mode => 644,
      content => template("erp_1_0/obao/application.yml.erb"),
      require => [Package["obao"]];
    "/etc/obao/mongoid.yml":
      owner =>"root", group => "root", mode => 644,
      content => template("erp_1_0/obao/mongoid.yml.erb"),
      require => [Package["obao"]];
    "/etc/obao/cert.p12":
      owner =>"obao", group => "obao", mode => 400,
      source => "${dist_files}/nodes/${hostname}/etc/obao/cert.p12",
      require => [Package["obao"]];
  }
}
