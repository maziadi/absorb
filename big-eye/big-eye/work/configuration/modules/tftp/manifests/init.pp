class tftp::server {
    package {
        "atftpd": ensure => present;
    }
    file {
        "/data/tftpboot": 
            owner => nobody, group => nogroup, mode => 755,
            ensure => directory;
    }
    replace { 
        tftp_use_inetd: 
            file => "/etc/default/atftpd",
            pattern => "USE_INETD=true",
            replacement => "USE_INETD=false",
            require => Package ["atftpd"],
            before => Service["atftpd"],
            notify => Service["atftpd"];
        tftp_dir: 
            file => "/etc/default/atftpd",
            pattern => " /tftpboot",
            replacement => "/data/tftpboot",
            require => Package ["atftpd"],
            before => Service["atftpd"],
            notify => Service["atftpd"];
    }
    service { 
        "atftpd":
            enable => true,
            ensure => running;
    }
}
