#module pour l'installation du opennms

class opennms::opennms {
  define cfg_file($notify = Service["opennms"], $mode = 644) {
    file {
      "${name}":
        owner => root,
        group => root,
        mode => $mode,
        source => [
          "${dist_files}/nodes/${hostname}/${name}",
          "${files_root}/opennms/${name}"
        ],
        notify => $notify,
        require => Package["opennms"];
    }
  }
 
  include system_1_0::debian
  include system_1_0::sun-jdk6
  include pgsql-83
  include snmpd_1_0::snmpd

  system_1_0::debian::add_apt_gpg_key { "opennms key": filename => "OPENNMS-GPG-KEY" } 
#  $files           = "${files_root}/opennms"
  $opennms_home    = "/usr/share/opennms"
  $snmpv3_authpass = $snmpd_1_0::snmpd::snmpv3_authpass
  $snmpv3_privpass = $snmpd_1_0::snmpd::snmpv3_privpass
  $snmpv3_username = $snmpd_1_0::snmpd::snmpv3_username
  
  case $opennms_create_lv { '': { $opennms_create_lv = false } }
  case $opennms_lv_size { '': { $opennms_lv_size = "100G" } }
  case $environment  {
    /^dev.*/         : { $opennms_loglevel="DEBUG" }
    default         : { $opennms_loglevel="INFO"  }
  }

  file {
    "/opt/local/share/opennms":
      mode    => 755,
      owner   => root,
      ensure  => directory;
  } 

  cfg_file {
    "/opt/local/bin/clean-logs-opennms.sh":
      mode => 755,
      notify => [];
    "/opt/local/bin/clean-db-events-opennms.sh":
      mode => 755,
      notify => [];
    "/opt/local/bin/create-nodes.sh":
      mode => 755,
      notify => [];
    "/opt/local/bin/import-nodes.sh":
      mode => 755,
      notify => [];

# ---------------------------------  Fichiers configurations qui ont besoin RESTART -----------------------------------
    "/opt/local/share/opennms/Alphalink.xml":
     notify => Exec["import nodes opennms"];
    "/etc/opennms/events/Alphalink.events.xml": ;
    "/etc/opennms/collectd-configuration.xml": ;
    "/etc/opennms/datacollection-config.xml": ;
    "/etc/opennms/eventconf.xml": ;
    "/etc/opennms/notifications.xml": ;
    "/etc/opennms/opennms.conf": ;
    "/etc/opennms/poller-configuration.xml": ;
    "/etc/opennms/threshd-configuration.xml": ;
    "/etc/opennms/thresholds.xml": ;
    "/opt/local/share/opennms/nodes.alloid": ;
    "/opt/local/share/opennms/nodes.base": ;
    "/opt/local/share/opennms/nodes.interfaces": ;
    "/opt/local/share/opennms/nodes.interfaces95": ;
    "/opt/local/share/opennms/nodes.voip": ;
    "/opt/local/share/opennms/nodes.apc": ;
    "/opt/local/share/opennms/nodes.switches.foundry": ;
# ---------------------------------------------- sans RESTART ------------------------------------------------
    "/etc/opennms/destinationPaths.xml":
      notify => [];
    "/etc/opennms/foreign-sources/Alphalink.xml":
      notify => [];
    "/etc/opennms/groups.xml":
      notify => [];
    "/etc/opennms/magic-users.properties":
      notify => [];
    "/etc/opennms/model-importer.properties":
      notify => [];
    "/etc/opennms/notifd-configuration.xml":
      notify => [];
    "/etc/opennms/notificationCommands.xml":
      notify => [];
    "/etc/opennms/snmp-graph.properties":
      notify => [];
    "/etc/opennms/response-graph.properties":
      notify => [];
    "/etc/opennms/surveillance-views.xml":
      notify => [];
  }
# ---------------------------------------------- TEMPLATES -----------------------------------------------------
  config_file {
    "/etc/opennms/snmp-config.xml":
      content => template("opennms/snmp-config.xml.erb"),
      require => Package["opennms"],      
      notify  => Service["opennms"],            #ce fichier a besoin RESTART opennms
      ensure  => present;

    "/etc/opennms/log4j.properties":
      content => template("opennms/log4j.properties.erb"),
      require => Package["opennms"],            #ce ficher N'a PAS besoin restart opennms
      ensure  => present;

    "/etc/opennms/log4j-controller.properties":
      content => template("opennms/log4j-controller.properties.erb"),
      require => Package["opennms"],            #ce ficher N'a PAS besoin restart opennms
      ensure  => present;

    "/etc/opennms/javamail-configuration.properties":
      content => template("opennms/javamail-configuration.properties.erb"),
      require => Package["opennms"],            #ce ficher N'a PAS besoin restart opennms
      ensure  => present;

    "/etc/opennms/users.xml":
      content => template("opennms/users.xml.erb"),
      require => Package["opennms"],            #ce ficher N'a PAS besoin restart opennms
      ensure  => present;
  }

  package {
    "opennms":
      ensure  => present,
      require => [
        Class["system_1_0::debian"],
        Class["system_1_0::sun-jdk6"]
      ];
#ces paquets sont nessesaires pour lancer /usr/share/opennms/bin/provision.pl
    "libxml-twig-perl":
      ensure  => present;
    "libhttp-body-perl":
      ensure  => present;
    "libstring-escape-perl":
      ensure  => present;

#ce paquet est pour avoir un outil snmpwalk sur le serveur opennms. Il ne s'agit pas du snmpd!      
    "snmp":
      ensure  => present;
  }

  service {
    "opennms":
      enable      => true,
      ensure      => running,
      hasrestart  => true,
      pattern     => '/usr/share/opennms/lib/opennms_bootstrap.jar',
      require     => Exec["initialize opennms"];
  }

  exec {
    "create database opennms":
      command => "sudo -u postgres createdb -U postgres -E UNICODE opennms",
      unless  => "sudo -u postgres psql -U postgres -c '\\l' |grep 'opennms'",
      require => [
        Package["sudo"],                    
        Class["pgsql-83"]
      ];

    "configure java":
      command => "${opennms_home}/bin/runjava -s",
      require => Package["opennms"];

    "initialize opennms":
      command => "${opennms_home}/bin/install -dis",
      onlyif  => "[ ! -f /etc/opennms/configured ] && echo 0",
      require => [
        Exec["create database opennms"],
        Exec["configure java"]
      ];

## 1ere alternative d'importation: utilisaton du script pour impoerter des nodes par provision.pl (RESTful)
#   "create nodes opennms":
#      command => "/opt/local/bin/create-nodes.sh",
#      require => [
#        Service["opennms"],
#        File["/opt/local/bin/create-nodes.sh"]
#     ];

# 2eme alternative d'importation: preparer le fichier XML avec des nodes et appeller reloadImport event par le script send-event.pl
   "import nodes opennms":
      command => "/usr/share/opennms/bin/send-event.pl uei.opennms.org/internal/importer/reloadImport --parm 'url file:/opt/local/share/opennms/Alphalink.xml'",
#      command => "/opt/local/bin/import-nodes.sh",

#  on ne peut pas utiliser refreshonly sur /opt/local/share/opennms/Alphalink.xml, car le fichier /etc/opennms/imports/Alphalink.xml peut etre modifie a partir WebUI de OpenNMS.
#     refreshonly => true,
      require => [
        Service["opennms"],
#        File["/opt/local/bin/import-nodes.sh"],
        File["/opt/local/share/opennms/Alphalink.xml"]
     ];
  }

  case $opennms_create_lv {
    true : {
      file {
        "/opt/local/bin/create-opennms-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          content => template("opennms/create-opennms-lv.erb");
      }
      exec {
        "Create OpenNMS LV":
          require => File["/opt/local/bin/create-opennms-lv"],
          unless => "lvdisplay /dev/data/opennms",
          command => "/opt/local/bin/create-opennms-lv",
          before => Package["opennms"]
      }
    }
  }
  
}
