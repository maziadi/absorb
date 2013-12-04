class erp_1_0::uixiv (
  $environment = "preproduction",
  $mongo_ip,
  $mongo = false,
  $url,
  $unicorn_workers,
  $uixiv_ip,
  $uixiv_port,
) {

  erp_1_0::rails_app {
    "uixiv":
      uid     => "1010",
      gid     => "1010",
      environment => $environment,
      ruby_version => "ruby-1.9.3-p125",
      unicorn_workers => $unicorn_workers,
      unicorn_timeout => "90",
      bind_address => $uixiv_ip,
      bind_port => $uixiv_port;
  }

  user {
    "www-data":
      groups => "uixiv",
      require => Group["uixiv"];
  }
  file {
    "/srv/uixiv/public":
      owner => uixiv, group => uixiv, mode => 755,
      ensure => directory,
      require => Package["uixiv"];
    "/etc/uixiv/application.yml":
      owner => root, group => root, mode => 644,
      content => template("erp_1_0/uixiv/application.yml.erb"),
      require => Package["uixiv"];
    "/etc/uixiv/mongoid.yml":
      owner => root, group => root, mode => 644,
      content => template("erp_1_0/uixiv/mongoid.yml.erb"),
      require => Package["uixiv"];
  }
  package {
      ["libmysqlclient-dev"]:
            ensure => present;
  }
  if $mongo {
    $mongo_bind_address= $mongo_ip
    include erp_1_0::mongodb-base
  }
}
