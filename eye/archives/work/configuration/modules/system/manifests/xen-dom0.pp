#
# Classe pour la creation d'un hote xen Dom0.
#
# $xen_network_script : determine le script utilise pour configurer le
#             reseau virtuel Xen (default: network-local)
#
# $xen_console: Ajoute la configuration de la console pour l'hyperviseur (true par defaut).
#
class system::xen-dom0 {
  $xen_network_script = $xen_network_script ? { 
    '' => 'network-dummy', 
    default => $xen_network_script 
  }
  case $xen_console { '': { $xen_console = true } }
  case $xen_dom0_mem { '': { $xen_dom0_mem = '512M' }}
  case $allow_migration { '': { $allow_migration = false } }

  if $xen_console {
    $xen_hopt = "dom0_mem=${xen_dom0_mem} ${xen_hopt} com1=19200,8n1"
  } else {
    $xen_hopt = "dom0_mem=${xen_dom0_mem}"
  }

  if $domu_on_san {
    $xen_tools_conf = "${files_root}/system/xen-domu-on-san/xen-tools.conf"
  } else {
    $xen_tools_conf = "${files_root}/system/xen-dom0/xen-tools.conf"
  }


  package { 
    "linux-image-2.6-xen-686": ensure => present;
    "xen-hypervisor-3.0.3-1-i386-pae": ensure => present;
    "xen-tools": ensure => present;
    "libc6-xen": ensure => present;
    "xen-ioemu-3.0.3-1": ensure => present;
    "xvncviewer": ensure => present;
    "vnc-common": ensure => present;
  }
  file {
    "/etc/xen/auto":
      owner => root, group => root, mode => 755,
      ensure => directory,
      require => Package["xen-hypervisor-3.0.3-1-i386-pae"];
    "/data/xen":
      owner => root, group => root, mode => 755,
      ensure => directory;
    "/etc/xen/xend-config.sxp":
      owner => root, group => root, mode => 644,
      content => template("system/xen-dom0/xend-config.sxp.erb"),
      require => Package["xen-hypervisor-3.0.3-1-i386-pae"];
    "/etc/xen/scripts/network-local":
      owner => root, group => root, mode => 755,
      content => template("system/xen-dom0/network-local.erb"),
      require => Package["xen-hypervisor-3.0.3-1-i386-pae"];
    "/usr/lib/xen-tools/debian.d/98-puppet":
      owner => root, group => root, mode => 755,
      source => "${files_root}/system/xen-dom0/puppet-hook",
      require => Package['xen-tools'];
    "/etc/xen-tools/xen-tools.conf":
      owner => root, group => root, mode => 644,
      source => $xen_tools_conf,
      #source => "${files_root}/system/xen-dom0/xen-tools.conf",
      require => Package['xen-tools'];
    "/usr/lib/xen-tools/debian.d/50-setup-hostname":
      owner => root, group => root, mode => 755,
      source => "${files_root}/system/xen-dom0/50-setup-hostname",
      require => Package['xen-tools'];
  }
  replace { "set_xenhopt to ${xenhopt}" :
    file => "/boot/grub/menu.lst",
    pattern => '^# ?xenhopt=.*$',
    replacement => "# xenhopt=${xen_hopt}",
    notify => Exec['update_grub'];
  }
						
  service {
    "xend":
      enable => true,
      ensure => running,
      hasrestart => true,
      subscribe => [ 
        File["/etc/xen/xend-config.sxp"], 
        File["/etc/xen/scripts/network-local"] 
      ];
  }
}
