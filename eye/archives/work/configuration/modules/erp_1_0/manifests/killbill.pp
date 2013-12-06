class erp_1_0::killbill (
  $environment = "preproduction",
  $db_host = "127.0.0.1",
  $db_password,
  $killbill_ip,
  $killbill_port,
) {
  erp_1_0::rails_app {
    "killbill":
      uid     => "1014",
      gid     => "1014",
      environment => $environment,
      ruby_version => "ruby-1.9.3-p374",
      unicorn_sql => true,
      unicorn_timeout => 90,
      bind_address => $killbill_ip,
      bind_port => $killbill_port;
  }
  package {
    ["libgdbm-dev", "libncurses5-dev", "libtool", "pkg-config", "libffi-dev","libmysqlclient-dev","wkhtmltopdf"]:
      ensure => present;
  }

  file {
    "/etc/killbill/database.yml":
      owner =>"killbill", group => "killbill", mode => 640,
      content => template("erp_1_0/killbill/database.yml.erb"),
      require => [Package["killbill"]];
  }
  postgresql_1_0::db {
    "killbill_${environment}":
      password => $db_password,
      owner => "killbill_${environment}",
      require => Package["postgresql-9.1"];
  }

}
