class voip_2_1::prov-as ( 
    $prov_as_user,
    $prov_as_password,
    $prov_activemq_host,
    $prov_as_db_user,
    $prov_as_db_password,
    $prov_as_db_name
  ) {
  package {
    "prov-as":
      ensure => present;
  }

  file {
    "/etc/default/prov-as":
      owner => root, group => root, mode => 640,  
      content => template("voip_2_1/prov/prov-as.erb"), 
      require => Package["prov-as"],
      before => Service["prov-as"];
  }

  service {
    "prov-as":
      enable => false,
      ensure  => running,
      hasstatus => false,
      pattern => '/prov-as',
      subscribe => File["/etc/default/prov-as"]
  }

  monit_1_0::monit::monit_file {
    "prov-as":
      requires => Package['prov-as'];
  }
 
}

class voip_2_1::prov-hss (
  $prov_hss_user,
  $prov_hss_password,
  $prov_activemq_host,
  $prov_hss_db_user,
  $prov_hss_db_password,
  $prov_hss_db_name
  ) {
  package {
    "prov-hss":
      ensure => present;
  }

  file {
    "/etc/default/prov-hss":
      owner => root, group => root, mode => 640,  
      content => template("voip_2_1/prov/prov-hss.erb"), 
      require => Package["prov-hss"],
      before => Service["prov-hss"];
  }

  service {
    "prov-hss":
      enable => false,
      ensure  => running,
      hasrestart => true,
      hasstatus => false,
      pattern => '/prov-hss',
      subscribe => File["/etc/default/prov-hss"]
  }
  
  monit_1_0::monit::monit_file {
    "prov-hss":
      requires => Package['prov-hss'];
  }
}

class voip_2_1::prov-routag (
  $prov_routag_user,
  $prov_routag_password,
  $prov_activemq_host,
  $routag_db_password,
  $prov_routag_db_user,
  $prov_routag_db_password,
  $prov_routag_db_name
) {
  package {
    "prov-routag":
      ensure => present;
  }

  file {
    "/etc/default/prov-routag":
      owner => root, group => root, mode => 640,  
      content => template("voip_2_1/prov/prov-routag.erb"), 
      require => Package["prov-routag"],
      before => Service["prov-routag"];
  }

  service {
    "prov-routag":
      enable => false,
      ensure  => running,
      hasstatus => false,
      pattern => '/prov-routag',
      subscribe => File["/etc/default/prov-routag"]
  }
  
  monit_1_0::monit::monit_file {
    "prov-routag":
      requires => Package['prov-as'];
  }
}
