class dnsmasq::dnsmasq {
    
    # devrait etre un parametre de la fonction dnsmasq::File

    case $other_name_servers {'': { $other_name_servers = [] } }

    package { 
        "dnsmasq": ensure => present;
    }
    config_file {
        "/etc/dnsmasq.conf":
            content => template("dnsmasq/dnsmasq.conf.erb"),
            require => Package["dnsmasq"];
    }
    file {
        "/etc/dnsmasq.d":
            ensure => directory,
            owner => root, group => root, mode => 755,
            require => Package["dnsmasq"];
    }
    service {
        "dnsmasq":
            ensure => running,
            hasrestart => true,
            enable => true,
            require => File["/etc/dnsmasq.conf"];
    }
}

define dnsmasq::file($content = '', $source = '', $files_prefix = $dist_files) {
  case "${content}${source}" {
    '': {
      host_file {
        "/etc/dnsmasq.d/${name}":
          before => Service["dnsmasq"],
          notify => Service["dnsmasq"]; 
      }
    }
    default: {
      config_file {
        "/etc/dnsmasq.d/${name}":
          files_prefix => $files_prefix,
          source => $source,
          content => $content,
          notify => Service["dnsmasq"]; 
      }
    }
  }
}
