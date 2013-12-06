class erp_1_0::mediation (
$cdrlog_create_lv = false,
$cdrlog_vg_name = "data",
$environment = "development",
$amq_voip_1_host,
$amq_voip_1_port = "61613",
$amq_voip_1_queues,
$amq_voip_2_host = $amq_voip_1_host,
$amq_voip_2_port = "61613",
$amq_voip_2_queues,
$amq_voip_user,
$amq_voip_passwd,
$amq_taxerp_1_host,
$amq_taxerp_1_port = "61613",
$amq_taxerp_2_host = $amq_taxerp_1_host,
$amq_taxerp_2_port = "61613",
$amq_taxerp_user,
$amq_taxerp_passwd,
$amq_taxerp_queues,
# si_rails
$erp_ip,
$erp_port,
$anderson_ip,
$anderson_port,
$taxman_ip,
$taxman_port,
$hector_ip,
$hector_port,
$pouss_mouss_ip,
$pouss_mouss_port,
$uixiv_ip,
$uixiv_port,
$drive_ip,
$drive_port,
$apnf_ip,
$apnf_port,
$killbill_ip,
$killbill_port,
$amq_si_host,
$amq_si_user,
$amq_si_passwd,
$amq_erp_host,
$amq_erp_user,
$amq_erp_passwd
) {
  class {
    "erp_1_0::si_rails_app_4":
      uid     => "1016",
      gid     => "1016",
      environment => $environment,
      app_name => "mediation",
      ruby_version=> "jruby-1.7.1",
      unicorn_start=> false,
      bind_address => $bind_address,
      bind_port => $bind_port,
      erp_ip => $erp_ip,
      erp_port => $erp_port,
      anderson_ip => $anderson_ip,
      anderson_port => $anderson_port,
      taxman_ip => $taxman_ip,
      taxman_port => $taxman_port,
      hector_ip => $hector_ip,
      hector_port => $hector_port,
      pouss_mouss_ip => $pouss_mouss_ip,
      pouss_mouss_port => $pouss_mouss_port,
      uixiv_ip => $uixiv_ip,
      uixiv_port => $uixiv_port,
      drive_ip => $drive_ip,
      drive_port => $drive_port,
      apnf_ip => $apnf_ip,
      apnf_port => $apnf_port,
      killbill_ip => $killbill_ip,
      killbill_port => $killbill_port,
      amq_si_host => $amq_si_host,
      amq_si_user => $amq_si_user,
      amq_si_passwd => $amq_si_passwd,
      amq_erp_host => $amq_erp_host,
      amq_erp_user => $amq_erp_user,
      amq_erp_passwd => $amq_erp_passwd,
      profile => "export MEDIATION_ENV=$environment\nexport JRUBY_OPTS=\"-J-XX:PermSize=256M -J-XX:MaxPermSize=512M -J-Xmn1024m -J-Xms2048m -J-Xmx2048m\"" ,
  }

  $monit_conf_alert_email = $monit::monit_conf_alert_email

  case $cdrlog_create_lv {
    true : {
      $lv_require = Exec["Create cdrlog LV"]
      file {
        "/opt/local/bin/create-cdrlog-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/erp_1_0/taxman/create-cdrlog-lv";
      }

      exec { "Create cdrlog LV":
        require => File["/opt/local/bin/create-cdrlog-lv"],
        unless => "lvdisplay /dev/${cdrlog_vg_name}/data",
        command => "/opt/local/bin/create-cdrlog-lv",
        before => Package["mediation"]
      }
    }
    false : {
      $lv_require = []
    }
  }

  monit_1_0::monit::monit_file {
    "mediation":
      requires => [Package["mediation"]];
  }

  host_file {
      "/etc/mediation/mongoid.yml": mode => 755;
      "/etc/default/cdr-archiver-cbv1": mode => 644;
      "/etc/default/cdr-archiver-cbv2": mode => 644;
  }

  file {
    "/data/cdr_archiver":
      owner => mediation, group => mediation, mode => 750,
      require => $lv_require,
      ensure => directory;
  }

  file {
    "/var/lib/cdr-archiver":
      ensure => link,
      target => "/data/cdr_archiver";
  }

  package {
    ["cdr-archiver-cbv1", "cdr-archiver-cbv2"]:
      ensure => present,
      require => File["/var/lib/cdr-archiver"];
  }

  file {
    "/etc/mediation/configuration.yml":
    mode => 755,
    content => template('erp_1_0/mediation/configuration.yml'),
    require => Package["mediation"];
  }


}
