class kvm_2_0::kvm (
  $cluster_nodes,
  $cluster_iface = "eth2",
  $openvswitch = false
) {
  Class['ha_3_0::pacemaker_heartbeat'] -> Class['kvm_2_0::kvm']
  package {
    [
      "libvirt0",
      "libvirt-bin",
      "qemu-kvm",
      "vnc4server",
      "virtinst",
      "uuid",
      "libcmdparse2-ruby",
      "libxml-simple-ruby",
      "liblog4r-ruby",
      "libopen4-ruby",
      "crmsh",
    ]:
      ensure => present;
  }
  case $lsbdistcodename {
    "squeeze":  {
      package {
        [
          "linux-image-2.6.39-bpo.2-amd64",
        ]:
          ensure => latest;
      }
    }
  }

  config_file {
    "/etc/libvirt/libvirtd.conf":
      owner => root, group => root, mode => 644,
      content => template("kvm_2_0/libvirtd.conf.erb"),
      require => Package["libvirt-bin"];
  }

  if $openvswitch == true {
    file {
      "/opt/local/bin/config_vserver":
        source => "${files_root}/kvm_2_0/config_vserver-ovs",
        mode => 700, owner => root, group => root;
      "/opt/local/bin/ovs-udev":
        source => "${files_root}/kvm_2_0/ovs-udev",
        mode => 755, owner => root, group => root;
      "/etc/udev/rules.d/ovs.rules":
        source => "${files_root}/kvm_2_0/ovs-udev-rules",
        mode => 755, owner => root, group => root;
    }
  }
  else {
    file {
      "/opt/local/bin/config_vserver":
        source => "${files_root}/kvm_2_0/config_vserver",
        mode => 700, owner => root, group => root;
    }
  }

  file {
    "/etc/rc.local":
      owner => root, group => root, mode => 644,
      content => template("kvm_2_0/rc.local.erb");
    "/etc/default/libvirt-bin":
      source => "${files_root}/kvm_2_0/libvirt-bin.default",
      mode => 644, owner => root, group => root;
    "/opt/local/bin/prepare_device":
      source => "${files_root}/kvm_2_0/prepare_device",
      mode => 700, owner => root, group => root;
    "/opt/local/bin/pm_vmprov.rb":
      source => "${files_root}/kvm_2_0/pm_vmprov.rb",
      mode => 700, owner => root, group => root;
    "/usr/lib/ruby/1.8/vmprov":
      source => "${files_root}/kvm_2_0/vmprov/vmprov",
      ensure => directory,
      recurse => true,
      owner => root, group => root;
    "/usr/lib/ruby/1.8/vmprov.rb":
      source => "${files_root}/kvm_2_0/vmprov/vmprov.rb",
      owner => root, group => root;
    "/usr/bin/vmprov":
      source => "${files_root}/kvm_2_0/vmprov.bin",
      owner => root, group => root;
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

  service {
    "libvirt-bin":
      enable => true,
      ensure => running,
      hasrestart => true,
      subscribe => [
        File["/etc/libvirt/libvirtd.conf"]
      ];
  }

  include system_1_0::debian-server-wheezy
  include rsyslog_1_0::rsyslog-client
  include vsftpd::vserver
  class {
    "ha_3_0::pacemaker_heartbeat":
      cluster_nodes => $cluster_nodes,
      cluster_bcasts => $cluster_iface,
      cluster_authkey => "952c6f97e301adb912db07a39062fd86",
      use_watchdog => true;
    "drbd_1_0::drbd_pacemaker":
      allow_dual_primary => true;
  }
  if $openvswitch {
    package {
      [
        "openvswitch-datapath-module",
        "openvswitch-switch",
        "openvswitch-test",
        "openvswitch-controller",
      ]:
        ensure => present;
    }
  }
}
