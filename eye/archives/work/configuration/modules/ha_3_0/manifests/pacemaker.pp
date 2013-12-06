#
# Pacemaker configuration
#
# $cluster_nodes: array of cluster node names 
# $cluster_authkey:  authentication keys to join the cluster
# $cluster_[u|b|m]casts: how to communicate with other nodes (see ha.cf manual)

class ha_3_0::pacemaker_heartbeat (
  $use_watchdog = false,
  $cluster_nodes,
  $cluster_ucasts = [],
  $cluster_bcasts = [],
  $cluster_mcasts = [],
  $cluster_authkey = "Cl3D3m3rD34cH4nG3"
) {
  package {
    "pacemaker":
      ensure => present;
  }
  Class['ha_3_0::heartbeat'] -> Class['ha_3_0::pacemaker_heartbeat']
  class {
    "ha_3_0::heartbeat":
      cluster_nodes => $cluster_nodes,
      authkey => $cluster_authkey,
      use_crm => true,
      use_serial => false,
      ucasts => $cluster_ucasts,
      bcasts => $cluster_bcasts,
      mcasts => $cluster_mcasts,
      use_watchdog => $use_watchdog
  }
}
