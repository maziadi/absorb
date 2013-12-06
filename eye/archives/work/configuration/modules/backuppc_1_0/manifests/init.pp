#modules backuppc_1_0
class backuppc_1_0::client {
}

class backuppc_1_0::server inherits backuppc_1_0::client {
  define create_cfg($backuppc_directory = "/", $backuppc_user = "") {
    file {
      "/etc/backuppc/${name}.pl":
        owner => backuppc, group => www-data, mode => 644,
        content => template("backuppc_1_0/host.pl.erb"),
        require => Package["backuppc"];
    }
    add_line {
      "ajout de la machine $name dans /etc/backuppc/hosts":
        pattern => "^$name[[:space:]]*0[[:space:]]backuppc",
        file => "/etc/backuppc/hosts",
        line => "$name 0 backuppc $backuppc_user",
        require => Package["backuppc"];
    }
    replace {
      "maj des backuppc users de la machine $name":
        file => "/etc/backuppc/hosts",
        pattern => "^$name[[:space:]]*0[[:space:]]backuppc.*",
        replacement => "$name 0 backuppc $backuppc_user",
        require => [Package["backuppc"], Add_line["ajout de la machine $name dans /etc/backuppc/hosts"]];
    }
  }

  case $backuppc_hostname        {'': { $backuppc_hostname        = "$hostname" } }
  case $backuppc_user            {'': { $backuppc_user            = "backuppc" } }
  case $backuppc_password        {'': { $backuppc_password        = "alphalink" } }
  case $backuppc_mail_domain     {'': { $backuppc_mail_domain     = "@alphalink.fr" } }
  case $backuppc_mail_user       {'': { $backuppc_mail_user       = "support" } }
  case $backuppc_keep_max_full   {'': { $backuppc_keep_max_full   = "[4, 0, 4, 0, 0, 2]" } }

  system_1_0::debian::debconf_set_selections {
    "backuppc backuppc/reconfigure-webserver multiselect apache2": package => "backuppc"
  }
  
  package {
    [
      "backuppc",
      "apache2",
    ]:
      ensure => present;
  }

  config_file {
    "/etc/backuppc/config.pl":
     owner => backuppc, group => www-data, mode => 644,
     content => template("backuppc_1_0/config.pl.erb"),
     notify  => Service["backuppc"],
     before  => Service["backuppc"],
     require => Package["backuppc"];
  }

  file {
    "/etc/apache2/conf.d/backuppc":
      ensure => "/etc/backuppc/apache.conf",
      notify => Service["apache2"];
  }
  host_file {
    [
      "/var/lib/backuppc/.ssh/id_dsa",
      "/var/lib/backuppc/.ssh/id_dsa.pub",
    ]: 
      ensure => present,
      require => Package["backuppc"];
  }
  exec {
    "create /etc/backuppc/htpasswd":
      command => "htpasswd -b /etc/backuppc/htpasswd $backuppc_user $backuppc_password",
      require => Package["backuppc"],
      notify  => Service["apache2"],
  }

  service {
    [    
      "apache2",
      "backuppc",
    ]:
      require => Package["backuppc"],
      enable => true,
      ensure => running;
  }
}


