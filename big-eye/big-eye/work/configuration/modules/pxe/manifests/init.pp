# Installation d'un serveur pxe

class pxe::pxe_1_0 inherits system_1_0::debian-server-squeeze {
    case $pxe_sub_network {'': { $pxe_sub_network = '169.254.96' } }
    case $pxe_network {'': { $pxe_network = '169.254.96.0/24' } }
    case $network_addr {'': { $network_addr = '169.254.96.0' } }
    case $pxe_server {'': { $pxe_server = '169.254.96.1' } }

    Package["portmap"] {
      ensure => present
    }

    package {
        [
            "nfs-common",
            "isc-dhcp-server",
            "tftpd-hpa",
            "nfs-kernel-server"
        ]: ensure => present;
    }

    config_file {
        "/etc/dhcp/dhcpd.conf":
            content => template("pxe/dhcpd.conf.erb"),
            notify => Service["isc-dhcp-server"],
            before => Service["isc-dhcp-server"],
            require => Package["isc-dhcp-server"];
        "/etc/exports":
            content => template("pxe/exports.erb"),
            require => Package["nfs-kernel-server"];
        "/etc/hosts.allow":
            content => template("pxe/hosts.allow.erb"),
            require => Package["nfs-kernel-server"];
        "/root/pxe-install":
            content => template("pxe/pxe-install.erb"),
            mode => 755;
    }
    exec {
        "pxe-install":
            command => "/root/pxe-install",
            require => [ File["/root/pxe-install"], File["/srv/debian-live"]],
            unless => "test -f /etc/pxe-${pxe_version}",
            timeout => 3600;
    }
    
    replace {
        "/etc/default/tftpd-hpa":
            file => "/etc/default/tftpd-hpa",
            pattern => "RUN_DAEMON=\"no\"",
            replacement => "RUN_DAEMON=\"yes\"",
            before => Service["tftpd-hpa"],
            require => Exec["pxe-install"];
        "/etc/default/tftpd-hpa-dir":
            file => "/etc/default/tftpd-hpa",
            pattern => "TFTP_DIRECTORY=\"/srv/tftp\"",
            replacement => "TFTP_DIRECTORY=\"/var/lib/tftpboot\"",
            before => Service["tftpd-hpa"],
            require => Exec["pxe-install"];
        "/var/lib/tftpboot/debian-live/i386/boot-screens/menu.cfg":
            file => "/var/lib/tftpboot/debian-live/i386/boot-screens/menu.cfg",
            pattern => "nfsroot=(.*):/srv/debian-live",
            replacement => "nfsroot=${pxe_server}:/srv/debian-live",
            notify => Service["tftpd-hpa"],
            require => Exec["pxe-install"];
    }

    service {
        "isc-dhcp-server":
            name => "isc-dhcp-server",
            require => Package["isc-dhcp-server"],
            hasstatus => true,
            ensure => running;
        "nfs-kernel-server":
            require => Package["nfs-kernel-server"],
            hasstatus => true,
            ensure => running;
        "tftpd-hpa":
            name => "tftpd-hpa",
            hasstatus => true,
            require => Package["tftpd-hpa"],
            ensure => running;        
    }
    file {
        "/srv/debian-live":
            ensure => directory,
            owner => root, group => root, mode => 755;
        "/srv/debian-live/live":
            ensure => directory,
            require => File["/srv/debian-live"],
            owner => root, group => root, mode => 755;
        "/srv/debian-live/live/system.dir":
            source => "${files_root}/pxe/srv/debian-live/live/system.dir", 
            mode => 755,
            owner => root,
            group => root,
            recurse => true,
            require => Exec["pxe-install"],
            notify => Service["nfs-kernel-server"];
        "/srv/debian-live/live/system.dir/etc/lisos/ssh/admin":
            owner => root, group => root, mode => 600,
            source => "${dist_files}/authorized_keys",
            require => [Exec["pxe-install"],File["/srv/debian-live/live/system.dir"]];
    }
}

class pxe::pxe inherits system_1_0::debian-server {
    case $pxe_sub_network {'': { $pxe_sub_network = '169.254.96' } }
    case $pxe_network {'': { $pxe_network = '169.254.96.0/24' } }
    case $network_addr {'': { $network_addr = '169.254.96.0' } }
    case $pxe_server {'': { $pxe_server = '169.254.96.1' } }

    Package["nfs-common"] {
      ensure => present
    }

    Package["portmap"] {
      ensure => present
    }

    package {
        [
            "dhcp3-server",
            "tftpd-hpa",
            "nfs-kernel-server"
        ]: ensure => present;
    }

    config_file {
        "/etc/dhcp3/dhcpd.conf":
            content => template("pxe/dhcpd.conf.erb"),
            notify => Service["dhcpd3"],
            before => Service["dhcpd3"],
            require => Package["dhcp3-server"];
        "/etc/exports":
            content => template("pxe/exports.erb"),
            require => Package["nfs-kernel-server"];
        "/etc/hosts.allow":
            content => template("pxe/hosts.allow.erb"),
            require => Package["nfs-kernel-server"];
        "/root/pxe-install":
            content => template("pxe/pxe-install.erb"),
            mode => 755;
    }
    exec {
        "pxe-install":
            command => "/root/pxe-install",
            require => File["/root/pxe-install"],
            unless => "test -f /etc/pxe-${pxe_version}",
            timeout => 3600;
    }
    
    replace {
        "/etc/default/tftpd-hpa":
            file => "/etc/default/tftpd-hpa",
            pattern => "RUN_DAEMON=\"no\"",
            replacement => "RUN_DAEMON=\"yes\"",
            before => Service["tftpd-hpa"],
            require => Exec["pxe-install"];
        "/var/lib/tftpboot/debian-live/i386/boot-screens/menu.cfg":
            file => "/var/lib/tftpboot/debian-live/i386/boot-screens/menu.cfg",
            pattern => "nfsroot=(.*):/srv/debian-live",
            replacement => "nfsroot=${pxe_server}:/srv/debian-live",
            notify => Service["tftpd-hpa"],
            require => Exec["pxe-install"];
    }

    service {
        "dhcpd3":
            name => "dhcp3-server",
            require => Package["dhcp3-server"],
            ensure => running;
        "nfs-kernel-server":
            require => Package["nfs-kernel-server"],
            ensure => running;
        "tftpd-hpa":
            name => "tftpd-hpa",
            require => Package["tftpd-hpa"],
            ensure => running;        
    }
    file {
        "/srv/debian-live/live/system.dir":
            source => "${files_root}/pxe/srv/debian-live/live/system.dir", 
            mode => 755,
            owner => root,
            group => root,
            recurse => true,
            require => Exec["pxe-install"],
            notify => Service["nfs-kernel-server"];
        "/srv/debian-live/live/system.dir/etc/lisos/ssh/admin":
            owner => root, group => root, mode => 600,
            source => "${dist_files}/authorized_keys",
            require => [Exec["pxe-install"],File["/srv/debian-live/live/system.dir"]];
    }
}
