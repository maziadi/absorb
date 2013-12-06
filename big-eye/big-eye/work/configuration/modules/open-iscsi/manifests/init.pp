# open-iscsi 
#
# $hostname

class open-iscsi::open-iscsi {
    
    case $hostname { '': { $hostname = "" } }

    package {
        "open-iscsi": ensure => present;
    }

    config_file {
# Le fichier de conf fournit par lenny est suffisant, pas de conf supp
        "/etc/iscsid.conf":
        	content => template("open-iscsi/iscsid.conf.erb"),
        	before => Service["iscsid"],
        	require => Package ["open-iscsi"];
        "/etc/initiatorname.iscsi":
            content => template("open-iscsi/initiatorname.iscsi.erb"),
            before => Service["iscsid"],
            mode => 600,
            require => Package ["open-iscsi"]; 
        "/etc/udev/rules.d/z99_iscsi-target.rules":
            content => template("open-iscsi/z99_iscsi-target.rules.erb"),
            notify => Service["udev"];
    }
    service {
        "udev":
            ensure => running;
        "iscsid":
          path => "/etc/init.d/open-iscsi",
          ensure => running;
    }
}

class open-iscsi::open-iscsi_2_0 {
    
    package {
        "open-iscsi": ensure => present;
    }

    file {
        "/etc/iscsi/iscsid.conf":
          source => "${files_root}/open-iscsi/iscsid.conf",
        	before => Service["iscsid"],
        	require => Package ["open-iscsi"];
    }
    service {
        "iscsid":
          path => "/etc/init.d/open-iscsi",
          ensure => running;
    }
}
