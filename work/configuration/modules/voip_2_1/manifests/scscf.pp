class voip_2_1::scscf(
$cdrlog_create_lv = false,
$cdrlog_vg_name = "data",
) {
  
  package { 
    [ "scscf-tools" ]:
      ensure => present 
  }

  # Ajout de dnsmasq pour gestion interne de noms de domaines
  $other_name_servers = ["217.15.80.4", "217.15.88.4"]

  include dnsmasq::dnsmasq
  case $dnsmasq_service_addr { '': { fail("dnsmasq_service_addr must be provided!") } }

  dnsmasq::file {
    "openvno.net":
      content => template("voip_2_1/scscf/openvno.net.erb");
  }

  class {
      "monit_1_0::monit":;
  } 
 
  monit_1_0::monit::monit_file {
     "dnsmasq":
       requires => Package["dnsmasq"];
  }

  file {
  "/root/screenrc":
    owner => root, group => root, mode => 640,
    source => "${files_root}/voip_2_1/scscf/root/screenrc";
  "/opt/local/bin/monitor_cdr_queue.sh":
    owner => root, group => root, mode => 755,
    content => template("voip_2_1/scscf/monitor_cdr_queue.sh.erb");
  "/etc/voip-tools.yaml":
    owner => root, group => root, mode => 640,
    content => template("voip_2_1/scscf/voip-tools.yaml.erb"),
    require => Package["scscf-tools"];
  }

  case $cdrlog_create_lv {
    true : {
      file {
        "/opt/local/bin/create-cdrlog-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/voip_2_1/scscf/opt/local/bin/create-cdrlog-lv";
      }

      exec { "Create cdrlog LV":
        require => File["/opt/local/bin/create-cdrlog-lv"],
        unless => "lvdisplay /dev/${cdrlog_vg_name}/data",
        command => "/opt/local/bin/create-cdrlog-lv"
      }
    }
    false : {
      exec { "Create cdrlog LV":
        unless => "true",
        command => "true"
      }
    }      
  }

  file {
    "/data/cdr_archiver":
      owner => root, group => root, mode => 750,
      require => Exec["Create cdrlog LV"],
      ensure => directory;
    "/var/lib/cdr-archiver":
      ensure => link,
      target => "/data/cdr_archiver";
  }

  cron {
    "monitor_cdr_queue":
      command => "/opt/local/bin/monitor_cdr_queue.sh",
      user    => root,
      minute  => '42',
      hour    => '*',
      ensure  => present;
  }
}
