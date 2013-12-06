class erp_1_0::taxman (
$webserver_taxman = false,
$cdrlog_create_lv = false,
$cdrlog_vg_name = "data",
$taxman_env = "development",
$allowing_hosts = ["127.0.0.1"],
$mongo_bind_address = "127.0.0.1",
$enable_mongodb = true,
$bind_address = "127.0.0.1",
$bind_port = "3001",
$taxman_apn_ip = "",
$taxman_apn_port="3002",
$amq_taxerp_1_host,
$amq_taxerp_1_port = "61613",
$amq_taxerp_2_host = $amq_taxerp_1_host,
$amq_taxerp_2_port = "61613",
$amq_taxerp_user,
$amq_taxerp_passwd,
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
$amq_erp_passwd,
) {
  class {
    "erp_1_0::si_rails_app_3":
      uid     => "1005",
      gid     => "1005",
      environment => $taxman_env,
      app_name => "taxman",
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
      profile => "export JRUBY_OPTS=\"-J-XX:PermSize=256M -J-XX:MaxPermSize=512M -J-Xmn1024m -J-Xms2048m -J-Xmx2048m\"" ,
  }

  case $enable_mongodb {
    true : {
      $mongo_replica_set = "taxman"
      include erp_1_0::mongodb-base
      monit_1_0::monit::monit_file {
         "mongodb-arbiter":
          requires => [Package["mongodb"],File["/var/lib/mongodb-arbiter"]];
      }
      file {
        "/etc/monitrc.d/mongodb-arbiter":
          ensure => absent;
        "/var/lib/mongodb-arbiter":
          owner => mongodb, group => mongodb, mode => 750,
          ensure => directory;
      }
    }
  }
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  include system_1_0::sun-jdk6

  #case $cdrlog_create_lv {
  #  true : {
  #    $lv_require = Exec["Create cdrlog LV"]
  #    file {
  #      "/opt/local/bin/create-cdrlog-lv":
  #        owner => root, group => root, mode => 700,
  #        ensure => present,
  #        source => "${files_root}/erp_1_0/taxman/create-cdrlog-lv";
  #    }

  #    exec { "Create cdrlog LV":
  #      require => File["/opt/local/bin/create-cdrlog-lv"],
  #      unless => "lvdisplay /dev/${cdrlog_vg_name}/data",
  #      command => "/opt/local/bin/create-cdrlog-lv",
  #      before => Package["taxman"]
  #    }
  #  }
  #  false : {
  #    $lv_require = []
  #  }
  #}

  monit_1_0::monit::monit_file {
    "taxman":
      requires => [Package["taxman"]];
  }

  file {
    "/etc/monitrc.d/taxman-consumer":
      ensure => absent;
    "/etc/monitrc.d/delayed_job_taxman":
      ensure => absent;
    "/etc/monitrc.d/taxman-apn":
      ensure => absent;
    "/etc/monitrc.d/taxman":
      ensure => absent;
  }
  host_file {
      "/etc/taxman/mongoid.yml": mode => 755;
      # Si médiation installée, virer les deux lignes ci-dessous.
     # "/etc/default/cdr-archiver-cbv1": mode => 644;
     # "/etc/default/cdr-archiver-cbv2": mode => 644;
  }

  file {
    "/etc/taxman/configuration.yaml":
    mode => 755,
    content => template('erp_1_0/taxman/configuration.yaml.erb'),
    require => Package["taxman"];
  }

  file {
    "/data/grid_sets":
      owner => taxman, group => taxman, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/call_logs":
      owner => taxman, group => taxman, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/accounting":
      owner => taxman, group => taxman, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/archives":
      owner => taxman, group => taxman, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/vno_journals":
      owner => taxman, group => taxman, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/csv_reports":
      owner => taxman, group => taxman, mode => 755,
      require => $lv_require,
      ensure => directory;
      # Si médiation installée, virer ce qui concerne cdr_archiver
    #"/data/cdr_archiver":
    #  owner => taxman, group => taxman, mode => 750,
    #  require => $lv_require,
    #  ensure => directory;
    #"/data/cdr_archives":
    #  owner => taxman, group => taxman, mode => 750,
    #  require => $lv_require,
    #  ensure => directory;
    "/data/mobile_batches":
      owner => taxman, group => taxman, mode => 750,
      require => $lv_require,
      ensure => directory;
    "/data/sfr":
      owner => taxman, group => taxman, mode => 750,
      require => $lv_require,
      ensure => directory;
#    "/data/sfr/tickets":
#      owner => taxman, group => taxman, mode => 750,
#      require => $lv_require,
#      ensure => directory;
    "/data/exports":
      owner => taxman, group => taxman, mode => 750,
      require => $lv_require,
      ensure => directory;
  }

#  # Si médiation installée, virer ce qui concerne cdr_archiver
#  file {
#    "/var/lib/cdr-archiver":
#      ensure => link,
#      target => "/data/cdr_archiver";
#  }

  file {
    "/opt/local/bin/ticketvalues.sh":
      owner => root, group => root, mode => 755,
      content => template('erp_1_0/taxman/ticketvalues.sh.erb');
  }

 # # Si médiation installée, virer ce qui concerne cdr_archiver
 # package {
 #   ["cdr-archiver-cbv1", "cdr-archiver-cbv2"]:
 #     ensure => present,
 #     require => File["/var/lib/cdr-archiver"];
 # }

  case $webserver_taxman {
    true : {
      file {
        "/etc/nginx/sites-enabled/taxman":
          owner => root, group => root, mode => 755,
          content => template('erp_1_0/taxman/taxman.nginx.erb'),
          require => Package["nginx"];
        # unicorn log
        "/var/log/taxman":
          owner => taxman, group => taxman, mode => 750,
          ensure => directory;
        "/etc/logrotate.d/unicorn-taxman":
          owner => root, group => root, mode => 644,
          source => "${files_root}/erp_1_0/taxman/unicorn-taxman-logrotate",
          notify => Service["monit"],
          require => [Package["monit"]];
      }
      package {
        "nginx":
          ensure => present;
      }
    }
  }
}
