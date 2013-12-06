class postgresql_1_0::cluster (
  $server_package = $postgresql_1_0::params::server_package,
  $version = $postgresql_1_0::params::version,
  $listen = $postgresql_1_0::params::listen_address,
  $port = $postgresql_1_0::params::port,
  $ssl = true,
  $postgresql_max_connections = $postgresql_1_0::params::postgresql_max_connections,
  $path_pgconf = "postgresql_1_0",
  $hb_ucasts=[],            # heartbeat ucasts : "interface nodeIP" form, second server
  $hb_bcasts=[],
  $nodes=[],                # heartbeat nodes : node1, node2
  $replicate_ip='',      # second DB IP
  $virtual_ip='',           # virtual IP on the master node, switched during failover
  $shared_buffers='24',
) inherits postgresql_1_0::params {

  class {
    "postgresql_1_0::server":
      server_package => $server_package,
      version => $version,
      listen => $listen,
      port => $port,
      ssl => $ssl,
      postgresql_max_connections => $postgresql_max_connections,
      cluster => true,
      replicate_ip => $replicate_ip,
      shared_buffers => $shared_buffers,
      path_pgconf => $path_pgconf;
    "ha_3_0::heartbeat":
      ucasts => $hb_ucasts,
      cluster_nodes => $nodes;
  }

  file {
    "/etc/postgresql/$version/main/start.conf":
      content => "manual";
    "/etc/postgresql/${version}/main/recovery.conf":
      owner => postgres, group => postgres, mode => 644,
      require => Package["postgresql-server-$version"],
      content => template("postgresql_1_0/recovery.conf.erb");
    "/var/lib/postgresql/primary2standby.sh":
      owner => postgres, group => postgres, mode => 755,
      require => Package["postgresql-server-$version"],
      content => template("postgresql_1_0/primary2standby.sh.erb");
    "/var/lib/postgresql/$version/main/recovery.conf":
      ensure => 'link',
      target => "/etc/postgresql/${version}/main/recovery.conf";
    "/var/lib/postgresql/$version/main/postgresql.conf":
      ensure => 'link',
      target => "/etc/postgresql/${version}/main/postgresql.conf";
    "/etc/ha.d/haresources":
      owner => root, group => root, mode => 644,
      content => template("postgresql_1_0/hb/haresources.erb"),
      require => Package["heartbeat"];
    "/etc/ha.d/resource.d/PostgreFailover":
      source => "${files_root}/postgresql_1_0/hb/PostgreFailover",
      mode => 755, owner => root, group => root,
      require => Package["heartbeat"];
  }

}
