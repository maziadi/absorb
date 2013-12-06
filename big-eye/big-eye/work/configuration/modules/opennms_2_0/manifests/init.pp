class opennms_2_0::opennms  inherits opennms_2_0::base {
  service {
    "opennms":
      enable      => true,
      ensure      => running,
      hasrestart  => true,
      pattern     => '/usr/share/opennms/lib/opennms_bootstrap.jar';
  }
}


class opennms_2_0::cluster  inherits opennms_2_0::base {
  service {
    "opennms":
      enable      => false;
  }
  service {
    "jetty":
      enable      => false,
      require     => Package["graph-opennms"];
  }
}



class opennms_2_0::base {
  define cfg_file($notify = [], $mode = 644) {
    file {
      "${name}":
        owner => root,
        group => root,
        mode => $mode,
        source => [
          "${dist_files}/nodes/${hostname}/${name}",
          "${files_root}/opennms_2_0/${name}"
        ],
        notify => $notify,
        require => Package["opennms"];
    }
  }
 
  case $lsbdistcodename {
    "squeeze": {
      package {
        "iplike-pgsql84":
          ensure => present,
          require => [ Class["pgsql"] ],
          before => Package["opennms"];
      }
    }
    default : {
      package {
        "iplike-pgsql83":
          ensure => present,
          require => [ Class["pgsql"] ],
          before => Package["opennms"];
      }
    }
  }
  include system_1_0::sun-jdk6
  include pgsql
  include snmpd_1_0::snmpd-squeeze

  system_1_0::debian::add_apt_gpg_key { "opennms key": filename => "OPENNMS-GPG-KEY" } 
  
  $opennms_home    = "/usr/share/opennms"
  $snmpv3_authpass = $snmpd_1_0::snmpd::snmpv3_authpass
  $snmpv3_privpass = $snmpd_1_0::snmpd::snmpv3_privpass
  $snmpv3_username = $snmpd_1_0::snmpd::snmpv3_username
  
  case $opennms_create_lv { '': { $opennms_create_lv = false } }
  case $opennms_lv_size { '': { $opennms_lv_size = "50G" } }

  case $opennms_login { '': { $opennms_login = "admin" } }
  case $opennms_password { '': { $opennms_password = "admin" } }
  case $opennms_api_password { '': { $opennms_api_password = "admin" } }
  case $opennms_max_vars_pdu { '': { $opennms_max_vars_pdu = "10" } }
  case $jetty_host { '': { $jetty_host = "127.0.0.1" } }

  case $caller_id { '': { $caller_id = "0970758267" } }
  case $account_code { '': { $account_code= "SIP/0990000001029" } }
  case $alert_nms { '': { $alert_nms = false } }
  case $alert_dahdi { '': { $alert_dahdi = false } }
  case $opennms_remote_ack_ip { '': { $opennms_remote_ack_ip = "127.0.0.1" } }

  case $opennms_java_heap { '': { $opennms_java_heap = "512" } }
  case $opennms_start_timeout { '': { $opennms_start_timeout = false } }
  case $opennms_cluster { '': { $opennms_cluster = false } }

  package {
    "opennms":
#      ensure => "1.8.15-1",
      require => [
        Class["system_1_0::sun-jdk6"]
      ];
    "libxml-twig-perl": ensure  => present;
    "libhttp-body-perl": ensure  => present;
    "libstring-escape-perl": ensure  => present;
    "snmp": ensure  => present;
    "libxml2-dev": ensure  => present;
    "libxslt1-dev": ensure  => present;
    "libstomp-ruby": ensure  => present;
    "libjson-ruby": ensure  => present;
    "jrrd": ensure => present;
    "graph-opennms":
        ensure => present,
        require => [
          Package["opennms"],
        ];
  }



  cfg_file {
    "/etc/opennms/poller-configuration.xml": ;
    "/etc/opennms/collectd-configuration.xml": ;
    "/etc/opennms/datacollection-config.xml": ;
    "/etc/opennms/datacollection/alphalink.xml": ;
    "/etc/opennms/eventconf.xml": ;
    "/etc/opennms/events/Alphalink.events.xml": ;
    "/etc/opennms/notifications.xml": ;
    "/etc/opennms/snmp-graph.properties": ;
    "/etc/opennms/snmp-graph.properties.d/alphalink.properties": ;
    "/etc/opennms/threshd-configuration.xml": ;
    "/etc/opennms/thresholds.xml": ;
    "/etc/opennms/notificationCommands.xml": ;
    "/etc/opennms/service-configuration.xml": ;
  }
  config_file {
    "/etc/opennms/snmp-config.xml":
      content => template("opennms_2_0/snmp-config.xml.erb"),
      require => Package["opennms"],      
      ensure  => present;

    "/etc/opennms/javamail-configuration.properties":
      content => template("opennms_2_0/javamail-configuration.properties.erb"),
      require => Package["opennms"],   
      ensure  => present;

    "/etc/opennms/opennms.conf":
      content => template("opennms_2_0/opennms.conf.erb"),
      require => Package["opennms"],   
      ensure  => present;

    "/etc/jetty/contexts/opennms.xml":
      content => template("opennms_2_0/opennms.xml.erb"),
      require => Package["graph-opennms"];

    "/etc/jetty/web_opennms.xml":
      content => template("opennms_2_0/web_opennms.xml.erb"),
      require => Package["graph-opennms"];

    "/etc/default/jetty":
      content => template("opennms_2_0/jetty.erb"),
      require => Package["graph-opennms"];
  }

  file {
    "/usr/share/java/webapps":
      owner => jetty, group => jetty, mode => 775,
      ensure => directory,
      require => Package["graph-opennms"];

    "/usr/share/opennms/jetty-webapps/opennms/WEB-INF/applicationContext-spring-security.xml":
        owner => root,
        group => root,
        mode => 644,
        source => "${files_root}/opennms_2_0/applicationContext-spring-security.xml",
        require => Package["opennms"];
  }


  case $opennms_cluster {
    false: {
      exec {
        "create database opennms":
          command => "sudo -u postgres createdb -U postgres -E UNICODE -T template0 opennms",
          unless  => "sudo -u postgres psql -U postgres -c '\\l' | grep -E '^ opennms.*'",
          before => Package["opennms"],
          require => [
            Package["sudo"],                    
            Class["pgsql"]
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

        "create database graph-opennms":
          command => "sudo -u postgres createdb -U postgres -E UNICODE -T template0 graph-opennms",
          unless  => "sudo -u postgres psql -U postgres -c '\\l' |grep -E '^ graph-opennms.*'",
          before => Package["graph-opennms"],
          require => [
            Package["sudo"],
            Class["pgsql"]
          ];

      }
    }
  }

  case $opennms_create_lv {
    true : {
      file {
        "/opt/local/bin/create-opennms-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          content => template("opennms_2_0/create-opennms-lv.erb");
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
  case $alert_nms {
    true : {
      package {
        "alert-nms": ensure  => present;
      }
      config_file {
        "/etc/caller_nms.yaml":
          content => template("opennms_2_0/caller_nms.yaml.erb"),
          require => Package["alert-nms"],
          ensure  => present;
        "/etc/jetty/contexts/alert-nms.xml":
          content => template("opennms_2_0/alert-nms.xml.erb"),
          require => Package["alert-nms"];
        "/etc/jetty/web_alert-nms.xml":
          content => template("opennms_2_0/web_alert-nms.xml.erb"),
          require => Package["alert-nms"];
        "/opt/local/bin/alert_opennms":
          owner => root, group => root, mode => 755,
          content => template("opennms_2_0/alert_opennms.erb"),
          require => Package["alert-nms"];
      }
    }
  }
}
