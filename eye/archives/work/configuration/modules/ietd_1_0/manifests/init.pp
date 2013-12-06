# ietd (iscsi-target) configuration for san storiq
#
# $targets : Target name

class ietd_1_0::ietd_1_0 {
  package {
    "iscsitarget-base": ensure => present;
  }

  host_file {
    "/etc/ietd.conf":
	    before => Service["iscsi-target"],
	    require => Package ["iscsitarget-base"];
  }

  service { "iscsi-target":
    subscribe => File["/etc/ietd.conf"]
  }
}

class ietd_1_0::ietd_2_0 {
  package {
    "iscsitarget": ensure => present;
    "iscsitarget-module-2.6.32-5-amd64": ensure => present;
  }
  file {
    "/opt/local/bin/manage_target":
      owner => root, group => root, mode => 755,
      source => "${files_root}/ietd_1_0/manage_target"
  }
}
