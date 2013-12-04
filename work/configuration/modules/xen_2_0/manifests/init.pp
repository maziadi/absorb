class xen_2_0::xen_2_0_base {
  # variables pour les xen-tools 

  case $xen_2_0_vgname      {'': { $xen_2_0_vgname      = 'data' } }
  case $xen_2_0_disk_size   {'': { $xen_2_0_disk_size   = '10Gb' } }
  case $xen_2_0_swap_size   {'': { $xen_2_0_swap_size   = '256Mb' } }
  case $xen_2_0_memory_size {'': { $xen_2_0_memory_size = '256Mb' } }
  case $xen_2_0_fs_type     {'': { $xen_2_0_fs_type     = 'xfs' } }
  case $xen_2_0_dist        {'': { $xen_2_0_dist        = 'lenny' } }
  case $xen_2_0_gateway     {'': { $xen_2_0_gateway     = '169.254.0.1' } }
  case $xen_2_0_netmask     {'': { $xen_2_0_netmask     = '255.255.254.0' } }
  case $xen_2_0_broadcast   {'': { $xen_2_0_broadcast   = '169.254.1.254' } }
  case $libvirt_listen_addr    { '': { $libvirt_listen_addr = false } }

  sysctl { "xen.independent_wallclock" : }

  package {
    [
      "xen-tools",
      "libvirt0",
      "libvirt-bin",
      "libcmdparse2-ruby",
      "libxml-simple-ruby",
    ]:
      ensure => present;
  }

  config_file { 
    "/etc/libvirt/libvirtd.conf":
      owner => root, group => root, mode => 644,
      content => template("xen_2_0/xen-dom0-lenny/libvirtd.conf.erb"),
      require => Package["libvirt-bin"];
  } 
  
  file {
    "/etc/default/libvirt-bin":
      source => "${files_root}/xen_2_0/libvirt-bin.default",
      mode => 644, owner => root, group => root;
    "/opt/local/bin/prepare_device":
      source => "${files_root}/xen_2_0/prepare_device",
      mode => 700, owner => root, group => root;
    "/opt/local/bin/install_vserver":
      source => "${files_root}/xen_2_0/install_vserver",
      mode => 700, owner => root, group => root;
    "/opt/local/bin/config_vserver":
      source => "${files_root}/xen_2_0/config_vserver",
      mode => 700, owner => root, group => root;
  }
  service {
    "libvirt-bin":
      enable => true,
      ensure => running,
      hasrestart => true,
      subscribe => [
         File["/etc/libvirt/libvirtd.conf"]
      ];
  }


  $active_atop = true
  include system_1_0::debian-server, xen_2_0::xen-dom0-lenny
}

class xen_2_0::xen_2_0_backbone {
  include xen_2_0::xen_2_0_base, open-iscsi::open-iscsi
}

class xen_2_0::xen_2_0_pornic {
  $xen_2_0_vgname      = 'data'
  $xen_2_0_gateway     = '10.0.44.1'
  $xen_2_0_netmask     = '255.255.255.0'
  $xen_2_0_broadcast   = '10.0.44.255'
  include xen_2_0::xen_2_0_base
}

class xen_2_0::xen_2_0_dual {
  include xen_2_0::xen_2_0_base, drbd_1_0::drbd_1_0_on_device 
}

class xen_2_0::xen_2_0_maquette {
  $xen_2_0_gateway     = '10.2.44.1'
  $xen_2_0_netmask     = '255.255.255.0'
  $xen_2_0_broadcast   = '10.2.44.255'
  include xen_2_0::xen_2_0_dual 
}

class xen_2_0::kvm_2_0_maquette {
  package {
    [
      "heartbeat-managevserver",
    ]:
      ensure => present;
  }

  $xen_2_0_gateway     = '10.2.44.1'
  $xen_2_0_netmask     = '255.255.255.0'
  $xen_2_0_broadcast   = '10.2.44.255'
  $ha_nodes = ["kvm-1-por1","kvm-2-por1"]
  $ha_bcasts = "eth1"
  $ha_mcasts = "xenbr0 239.0.0.1 694 1 0"
  $ha_authkey = "da066ef4cc65196dce2d5aea352b311f1ffd96d5"
  $ha_ressources        = [ 
    "kvm-1-por1 ManageVserver::paravirt-1-por1",
  ]

  host_file {
    "/etc/rc.local":;
  }

  $snmp_maquette     = true
  $repositories = [ "lenny",  "lenny-dev" ]
  $activate_proxy_apt = false
  
  ## drbd
  $drbd_1_0_resource             = "drbd2"
  $drbd_1_0_primary_hostname     = "kvm-1-por1"
  $drbd_1_0_primary_address      = "10.3.44.3"
  $drbd_1_0_secondary_hostname   = "kvm-2-por1"
  $drbd_1_0_secondary_address    = "10.3.44.4"
  $drbd_1_0_disk                 = "ocfs2"
  $drbd_1_0_device               = $drbd_1_0_resource
  $drbd_1_0_port                 = "7791"
  $ocfs2_1_0_primary_hostname    = $drbd_1_0_primary_hostname
  $ocfs2_1_0_secondary_hostname  = $drbd_1_0_secondary_hostname
  $ocfs2_1_0_primary_address     = $drbd_1_0_primary_address
  $ocfs2_1_0_secondary_address   = $drbd_1_0_secondary_address


  include xen_2_0::xen_2_0_base, drbd_1_0::drbd_1_0_on_device, ha_2_0::ha_2_0, ocfs2_1_0::base
}
  

