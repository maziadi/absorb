#
# Heartbeat 3 High Availability (HA) configuration
#
# $ha_nodes: array of HA node names 

class ha_3_0::heartbeat (
  $use_serial = false,
  $use_watchdog = false,
  $cluster_nodes,
  $ucasts = [],
  $bcasts = [],
  $mcasts = [],
  $auto_failback = "off",
  $authkey = "Cl3D3m3rD34cH4nG3",
  $use_crm = false,
  $deadping = false,
  $deadping_time = false,
  $debug_level = "0",
  $copyfiles = false
) {
  package {
    "heartbeat":
      ensure => present;
  }

  config_file { 
    "/etc/ha.d/ha.cf": 
      content => template("ha_3_0/ha.cf.erb"),
      before => Service["heartbeat"],
      require => Package["heartbeat"];
    "/etc/ha.d/authkeys": 
      content => "auth 1\n1 sha1 ${authkey}\n",
      mode => 600, owner => root,
      before => Service["heartbeat"],
      require => Package["heartbeat"];
  } 

  service {
    "heartbeat":
      enable   => true,
      ensure  => running;
  }

  if $copyfiles {
    file {
      "/etc/ha.d/haresources":
        owner => root, group => root, mode => 644,
        source => "${dist_files}/nodes/${hostname}/etc/ha.d/haresources",
        require => Package["heartbeat"];
      "/etc/ha.d/resource.d":
        ensure => directory,
        recurse => true,
        owner => root, group => root, mode => 755,
        source => "${dist_files}/nodes/${hostname}/etc/ha.d/resource.d",
        require => Package["heartbeat"];
    }
  }

}
