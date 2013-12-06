class mantis {
    package {
        "libapache2-mod-php5": ensure => present
    }
    apache_module { "php5": ensure => present }

    system::debian::debconf_set_selections { 
        "mantis mantis/dbconfig-install boolean true": package => "mantis" 
    }
    package {
        "mantis": ensure => present
    }

    include mysql

    config_file { 
        "/etc/dbconfig-common/mantis.conf" :
            content => template("mantis/mantis-dbconfig.conf.erb"),
            require => Package["mantis"];
    }
    host_file { "/etc/mantis" : recurse => true; }
}
