#
# Classe pour la creation d'un hote xen Dom0.
#
# $xen_network_script : determine le script utilise pour configurer le
#             reseau virtuel Xen (default: network-local)
#
# $xen_console: Ajoute la configuration de la console pour l'hyperviseur (true par defaut).
#
class xen_2_0::xen-dom0-lenny {

  case $xen_network_script { '': { $xen_network_script = 'network-dummy' } }
  case $xen_console        { '': { $xen_console = false } }
  case $xen_dom0_mem       { '': { $xen_dom0_mem = '512M' }}
  case $allow_migration    { '': { $allow_migration = true } }
  case $xen_2_0_portal     { '': { $xen_2_0_portal = "169.254.62.101" } }

  if $xen_console {
    $xen_hopt = "dom0_mem=${xen_dom0_mem} noreboot ${xen_hopt} com1=19200,8n1"
  } else {
    $xen_hopt = "dom0_mem=${xen_dom0_mem} noreboot"
  }

  case $architecture {
    amd64: { 
      package { 
        [
          "linux-modules-xen-amd64",
          "xen-linux-system-2.6.26-2-xen-amd64",
          "vncserver",
        ] : ensure => present;
      }
      file {
        "/etc/xen/auto":
          owner => root, group => root, mode => 755,
          ensure => directory,
          require => Package["xen-linux-system-2.6.26-2-xen-amd64"];
        "/etc/xen/xend-config.sxp":
          owner => root, group => root, mode => 644,
          content => template("xen_2_0/xen-dom0-lenny/xend-config.sxp.erb"),
          require => Package["xen-linux-system-2.6.26-2-xen-amd64"];
        "/data/xen":
          owner => root, group => root, mode => 755,
          ensure => directory,
          require => Package["xen-linux-system-2.6.26-2-xen-amd64"];
        "/etc/xen/scripts/network-local":
          owner => root, group => root, mode => 755,
          content => template("xen_2_0/xen-dom0-lenny/network-local.erb"),
          require => Package["xen-linux-system-2.6.26-2-xen-amd64"];
      }
    }
    i386: {  
      package { 
        [
          "linux-modules-xen-686",
          "xen-linux-system-2.6.26-2-xen-686",
          "vncserver",
        ] : ensure => present;
      }
      file {
        "/etc/xen/auto":
          owner => root, group => root, mode => 755,
          ensure => directory,
          require => Package["xen-linux-system-2.6.26-2-xen-686"];
        "/etc/xen/xend-config.sxp":
          owner => root, group => root, mode => 644,
          content => template("xen_2_0/xen-dom0-lenny/xend-config.sxp.erb"),
          require => Package["xen-linux-system-2.6.26-2-xen-686"];
        "/data/xen":
          owner => root, group => root, mode => 755,
          ensure => directory,
          require => Package["xen-linux-system-2.6.26-2-xen-686"];
        "/etc/xen/scripts/network-local":
          owner => root, group => root, mode => 755,
          content => template("xen_2_0/xen-dom0-lenny/network-local.erb"),
          require => Package["xen-linux-system-2.6.26-2-xen-686"];
      }
      host_file {
      "/etc/xen/":
        ensure => present,
        owner => root, group => root, mode => 755,
        recurse => true;
      }
    }
  }


  file {
    "/opt/local/bin/optimisation-target-xen":
      owner => root, group => root, mode => 700,
      content => template("xen_2_0/xen-dom0-lenny/optimisation-target-xen");
    "/opt/local/bin/iscsi-management":
      owner => root, group => root, mode => 700,
      content => template("xen_2_0/xen-dom0-lenny/iscsi-management.erb");
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
        File["/etc/xen/xend-config.sxp"] 
      ];
  }
}
