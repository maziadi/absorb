class erp_1_0::drive (
  $environment = "preproduction",
  $db_host,
  $drive_ip,
  $drive_port,
) {
  erp_1_0::rails_app {
    "drive":
      uid     => "1013",
      gid     => "1013",
      environment => $environment,
      ruby_version => "ruby-1.9.3-p194",
      unicorn_timeout => "150",
      bind_address => $drive_ip;
  }

  package {
    ["libmysqlclient-dev"]:
      ensure => present;
  }
  file {
    "/etc/drive/mongoid.yml":
      owner =>"drive", group => "drive", mode => 640,
      content => template("erp_1_0/drive/mongoid.yml.erb"),
      require => [Package["drive"]];
    "/etc/monit/conf.d/delayed_job_drive":
      owner =>"root", group => "root", mode => 640,
      content => template("erp_1_0/drive/monit_delayed_job.erb"),
      require => [Package["drive"]];
  }
  $app_name = "drive"
  monit_1_0::monit::monit_file {
    "messenger":
       requires => Package["drive"];
  }
}
