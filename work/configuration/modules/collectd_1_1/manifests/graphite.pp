class collectd_1_1::graphite-carbon (
  cache_servers = []
) {

  package {
    "graphite-carbon":
      ensure => present;
  }

  file {
    "/etc/carbon/carbon.conf":
      content => template('collectd_1_1/graphite/carbon.conf.erb'),
      require => Package["graphite-carbon"];
    "/etc/carbon/storage-schemas.conf":
      source => "${files_root}/collectd_1_1/graphite/storage-schemas.conf",
      require => Package["graphite-carbon"];
    "/etc/carbon/relay-rules.conf":
      content => template('collectd_1_1/graphite/relay-rules.conf.erb'),
      require => Package["graphite-carbon"];
    "/var/lib/graphite":
      owner => "_graphite", group => "_graphite", mode => 755,
      require => Package["graphite-carbon"],
      ensure => directory;
    "/etc/default/graphite-carbon":
      before => Package["graphite-carbon"],
      content => "CARBON_CACHE_ENABLED=false";
  }
  monit_1_0::monit::monit_file {
    "graphite-carbon":
      requires => Package["graphite-carbon"];
  }
}

class collectd_1_1::graphite-web (
  pgsql = false,
  pgsql_ip = "127.0.0.1",
  pgsql_passwd = "",
  cluster_servers = []
) {

  package {
    "graphite-web":
      ensure => present;
    "gunicorn":
      ensure => present;
    "python-psycopg2":
      ensure => present;
  }

  if $pgsql {
    $postgresql_trusted_addresses = $cluster_servers
    class {
      "postgresql_1_0::server":
        version => "9.2",
        ssl => false,
        listen => $pgsql_ip;
    }
    postgresql_1_0::db {
      "graphite":
        password => $pgsql_passwd,
        owner => "graphite",
        require => Package["postgresql-9.2"];
    }

  }

  class {
    "nginx_1_0::nginx":
      default_www_directory => "/var/www/",
      port => '80',
      servername => $hostname;
    "monit_1_0::monit":;
  }

  monit_1_0::monit::monit_file {
    "graphite-web":
      requires => Package["graphite-web"];
  }

  file {
    "/etc/graphite/local_settings.py":
      content => template('collectd_1_1/graphite/local_settings.py.erb'),
      require => Package["graphite-web"];
    "/etc/graphite/dashboard.conf":
      source => "${files_root}/collectd_1_1/graphite/dashboard.conf",
      require => Package["graphite-web"];
    "/etc/gunicorn.d/graphite-web":
      source => "${files_root}/collectd_1_1/graphite/graphite-web-gunicorn",
      require => Package["gunicorn"];
    "/etc/nginx/sites-enabled/graphite-web":
      source => "${files_root}/collectd_1_1/graphite/graphite-web-nginx",
      notify => Service["nginx"],
      require => Package["nginx"];
  }
}
