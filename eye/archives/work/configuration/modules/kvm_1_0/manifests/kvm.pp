class kvm_1_0::kvm_1_0_base {
  case $libvirt_listen_addr    { '': { $libvirt_listen_addr = false } }
  case $kvm_1_0_vgname         { '': { $kvm_1_0_vgname = "data" } }

  package {
    [
      "heartbeat-managevserver",
      "heartbeat-interface",
      "kpartx",
      "libvirt0",
      "libvirt-bin",
      "libcmdparse2-ruby",
      "libxml-simple-ruby",
      # forcer tant que l'on est en lenny
      "linux-image-2.6.32-bpo.3-amd64",
      "qemu-kvm",
      "virtinst",
      "vnc4server",
    ]:
      ensure => present;

  }

  config_file { 
    "/etc/libvirt/libvirtd.conf":
      owner => root, group => root, mode => 644,
      content => template("kvm_1_0/libvirtd.conf.erb"),
      require => Package["libvirt-bin"];
  } 
  
  file {
    "/etc/default/libvirt-bin":
      source => "${files_root}/kvm_1_0/libvirt-bin.default",
      mode => 644, owner => root, group => root;
    "/opt/local/bin/prepare_device":
      source => "${files_root}/kvm_1_0/prepare_device",
      mode => 700, owner => root, group => root;
    "/opt/local/bin/install_vserver":
      source => "${files_root}/kvm_1_0/install_vserver",
      mode => 700, owner => root, group => root;
    "/opt/local/bin/config_vserver":
      source => "${files_root}/kvm_1_0/config_vserver",
      mode => 700, owner => root, group => root;
    "/etc/libvirt/qemu":
      owner => root, group => root,
      source => "${dist_files}/nodes/${hostname}/etc/libvirt/qemu",
      ensure => directory,
      mode => 644,
      recurse => true;
    "/etc/lvm/lvm.conf":
      source => "${files_root}/kvm_1_0/lvm.conf",
      mode => 644, owner => root, group => root;
  }

  host_file {
    "/etc/rc.local":;
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
  include system_1_0::debian-server
  include rsyslog_1_0::rsyslog-client
}

class kvm_1_0::kvm_1_0_dual {
  include kvm_1_0::kvm_1_0_base, drbd_1_0::drbd_1_0_on_device, ha_2_0::ha_2_0, vsftpd::vserver 
}


