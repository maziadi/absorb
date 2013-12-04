class erp_1_0::pouss-mouss (
  $environment = "preproduction",
  $db_host, $bind_address, $bind_port, $pnm_user, $pnm_password,
) {

  erp_1_0::rails_app {
    "pouss-mouss":
      uid     => "1012",
      gid     => "1012",
      environment => $environment,
      ruby_version => "ruby-1.9.3-p194",
      bind_address => $bind_address,
      bind_port => $bind_port;
  }

  package {
    ["libmysqlclient-dev"]:
      ensure => present;
  }

  file {
    "/etc/pouss-mouss/application.yml":
      owner =>"pouss-mouss", group => "pouss-mouss", mode => 640,
      content => template("erp_1_0/pouss-mouss/application.yml.erb"),
      require => [Package["pouss-mouss"]];
    "/etc/pouss-mouss/mongoid.yml":
      owner =>"pouss-mouss", group => "pouss-mouss", mode => 640,
      content => template("erp_1_0/pouss-mouss/mongoid.yml.erb"),
      require => [Package["pouss-mouss"]];
     "/etc/monit/conf.d/delayed_job_pouss-mouss":
       owner =>"root", group => "root", mode => 640,
       content => template("erp_1_0/pouss-mouss/monit_delayed_job.erb"),
       require => [Package["pouss-mouss"]];
  }
  $app_name = "pouss-mouss"
  monit_1_0::monit::monit_file {
    "messenger":
       requires => Package["pouss-mouss"];
  }
}
