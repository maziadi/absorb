#
# Heartbeat High Availability (HA) configuration
#
# $ha_nodes: array of HA node names 
# $ha_authkey:  authentication keys file content 
# $ha_resources: table of couples, each couple is composed of a prefered

class ha_2_0::ha_2_0 {
  case $ha_serial        { '': { $ha_serial        = false } }
  case $ha_nodes         { '': { $ha_nodes         = [] } }
  case $ha_ucasts        { '': { $ha_ucasts        = [] } }
  case $ha_bcasts        { '': { $ha_bcasts        = [] } }
  case $ha_mcasts        { '': { $ha_mcasts        = [] } }
  case $ha_ressources    { '': { $ha_ressources    = [] } }
  case $ha_authkey_type  { '': { $ha_authkey_type  = "sha1" } }
  case $ha_auto_failback { '': { $ha_auto_failback = "off" } }
  case $ha_authkey       { '': { $ha_authkey       = "" } }
  case $ha_crm           { '': { $ha_crm           = false } }
  case $ha_deadping      { '': { $ha_deadping      = false } }
  case $ha_deadping_time { '': { $ha_deadping_time = "10" } }
  case $debug_level      { '': { $debug_level      = "0" } }

  package {
    [
      "heartbeat",
    ]: ensure => present;
  }


  config_file { 
    "/etc/ha.d/ha.cf": 
      content => template("ha_2_0/ha.cf.erb"),
      before => Service["heartbeat"],
      require => Package["heartbeat"];
    "/etc/ha.d/haresources": 
      content => template("ha_2_0/haresources.erb"), 
      before => Service["heartbeat"],
      require => Package["heartbeat"];
    "/etc/ha.d/authkeys": 
      content => template("ha_2_0/authkeys.erb"),
      mode => 600,
      before => Service["heartbeat"],
      require => Package["heartbeat"];
  } 

#  file {
#    [
#      "/sbin/drbdsetup",
#      "/sbin/drbdmeta",
#    ] : owner => root, group => haclient, mode => 4754;
#    "/tmp/basic.xml":
#      ensure    => present,
#      content   => template("ha_2_0/basic.xml"),
#      require   => Service["heartbeat"],
#      before    => Exec["initialize_cluster"];
#  }
#
#  exec {
#    "initialize_cluster":
#      command   =>  "cibadmin -C -o crm_config -x /tmp/basic.xml",
#      unless    =>  "cibadmin -Q | grep bootstrap01",
#      require   =>  Service["heartbeat"];
#  }
  
  service {
    "heartbeat":
      enable   => true,
      ensure  => running;
  }

}

