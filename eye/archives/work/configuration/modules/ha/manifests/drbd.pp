class ha::drbd {

    define ressource($node1_name, $node1_disk, $node1_address, $node2_name, $node2_disk, $node2_address) {
        $ressource = $name

        file {
            "/etc/drbd.conf":
                owner => root, group => root, mode => 644,
                content => template("ha/drbd.conf.erb"),
                notify => Service["drbd"],
                require => Package["drbd8-utils"];
        }
    }
    
    # - cree le media si il existe pas
    # - cree le mountpoint si il existe pas
    # - monte la ressource si pas montee et ajout dans fstab si pas present
   define create_md($vg_name = "data", $lv_name = "drbd0", $size = "1G", $mountpoint = "/mnt/drbd") {
        
        create_lv { 
            "${lv_name}": 
                vg_name => $vg_name,
                size => $size;
        }

        exec {
            "restart(0) drbd":
                command => "/etc/init.d/drbd stop && /etc/init.d/drbd start",
                subscribe => File["/etc/drbd.conf"],
                refreshonly => true;
            "drbd create-md ${name}":
                command => "yes yes | drbdadm create-md ${name}",
                unless => "drbdadm get-gi ${name}",
                notify => Service["drbd"],
                require => [Create_lv["${lv_name}"],Exec["restart(0) drbd"]];
        }
        file {
            "${mountpoint}":
                owner => root, group => root, mode => 755,
                ensure => directory;
        }
        add_line {
            "ajout d'une entree pour ${name} dans /etc/fstab":
                file => "/etc/fstab",
                line => "/dev/${name}      ${mountpoint}       reiserfs        rw,noauto       0       0";
        }
#        mount {
#            "${mountpoint}":
#                device => "/dev/${name}",
#                fstype => "reiserfs",
#                options => "rw,noauto",
#                target => "/etc/fstab",
#                ensure => present,
#                require => File["${mountpoint}"];
#        }
    }
    
    # - passe la ressource en primaire si elle existe (sinon la cree)
    # - formate la partition si elle est pas formatee
    # ET TOUT CA QUE A LINSTALL DU NOEUD PRIMAIRE
    define mount_md($mountpoint = "/mnt/drbd") {
        file {
            "/opt/local/bin/mount-md-${name}.sh":
                owner => root, group => root, mode => 755,
                content => template("ha/mount-md.sh.erb"),
                ensure => present;
        }
        exec {
            "restart(1) drbd":
                command => "/etc/init.d/drbd stop && /etc/init.d/drbd start",
                onlyif => "cat /proc/drbd | grep Unconfigured",
                require => create_md["${name}"];
            "execute mount-md-${name}.sh":
                command => "/opt/local/bin/mount-md-${name}.sh puppet",
                unless => "test -e /etc/flags/drbd-dont-mount-md-${name}.flag",
                require => [Exec["restart(1) drbd"],File["/opt/local/bin/mount-md-${name}.sh"]];
        }
    }
    
    package {
        "drbd8-$kernelrelease":
            ensure => present;
        "drbd8-utils":
            require => Package["drbd8-$kernelrelease"],
            ensure => present;
    }
    service {
        "drbd":
            enable => true,
            ensure => running,
            hasrestart => false,
    }
}
