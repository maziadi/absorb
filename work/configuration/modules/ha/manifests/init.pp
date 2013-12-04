#
# Heartbeat High Availability (HA) configuration
#
# $ha_nodes: array of HA node names 
# $ha_authkeys:  authentication keys file content 
# $ha_resources: table of couples, each couple is composed of a prefered

class ha::ha {
  define ha_service_restart() {
    file {
      "/etc/ha.d/resource.d/${name}-restart":
        owner => root, group => root, mode => 755,
        content => template("ha/restart.erb");
    }
  }
  package {
    "heartbeat-2": ensure => present;
  }

  case $ha_serial { '': { $ha_serial = true } }
  case $ha_nodes { '': { $ha_nodes = [] } }
  case $ha_ucasts { '': { $ha_ucasts = [] } }
  case $ha_bcasts { '': { $ha_bcasts = [] } }
  case $ha_ressources { '': { $ha_ressources = [] } }
  case $ha_authkey_type { '': { $ha_authkey_type = "md5" } }
  case $ha_auto_failback { '': { $ha_auto_failback = "on" } }
  case $ha_authkey { '': { $ha_authkey = "06ac46372d0f111fccac2ce96578a47e" } }
  case $ha_crm { '': { $ha_crm = false } }
  case $ha_deadping { '': { $ha_deadping = false } }
  case $ha_deadping_time { '': { $ha_deadping_time = "10" } }
  case $debug_level { '': { $debug_level = "1" } }

  case $ha_gui {
    true: {
      package {
        [
          "heartbeat-2-gui",
          "xbase-clients"
        ]: ensure => present;
      }
    }
  } 

  config_file { 
    "/etc/ha.d/ha.cf": 
      content => template("ha/ha.cf.erb"),
#      before => Service["heartbeat"],
      require => Package["heartbeat-2"];
    "/etc/ha.d/haresources": 
      content => template("ha/haresources.erb"), 
#      before => Service["heartbeat"],
      require => Package["heartbeat-2"];
    "/etc/ha.d/authkeys": 
      content => template("ha/authkeys.erb"),
      mode => 600,
#      before => Service["heartbeat"],
      require => Package["heartbeat-2"];
  } 

#  service {
#    "heartbeat":
#      enable   => true,
#      ensure  => running;
#  }
}
