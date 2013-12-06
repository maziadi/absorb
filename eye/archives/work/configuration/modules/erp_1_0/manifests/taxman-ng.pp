class erp_1_0::taxman-daemons (
$cdrlog_create_lv = false,
$cdrlog_vg_name = "data",
$environment = "development",
$taxman_pg_host,
$taxman_pg_pool_size = "16",
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
) {
  erp_1_0::rails_app {
    "taxman-daemons":
      uid     => "1017",
      gid     => "1017",
      environment => $environment,
      ruby_version=> "jruby-1.7.1",
      unicorn_start=> false,
      bind_address => $bind_address,
      bind_port => $bind_port,
      profile => "export DAEMONS_ENV=$environment\nexport JRUBY_OPTS=\"-J-XX:PermSize=256M -J-XX:MaxPermSize=512M -J-Xmn1024m -J-Xms2048m -J-Xmx2048m\"" ,
  }

  $monit_conf_alert_email = $monit::monit_conf_alert_email

  monit_1_0::monit::monit_file {
    "taxman-daemons":
      requires => [Package["taxman-daemons"]];
  }

  file {
    "/srv/taxman-daemons/config/configuration.yml":
      owner => taxman-daemons, group => taxman-daemons, mode => 660,
      content => template('erp_1_0/taxman-common/configuration.yml.erb'),
      require => Package["taxman-daemons"];
    "/srv/taxman-daemons/config/database.yml":
      owner => taxman-daemons, group => taxman-daemons, mode => 660,
      content => template('erp_1_0/taxman-common/database.yml.erb'),
      require => Package["taxman-daemons"];
  }

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
        before => Package["taxman-daemons"]
      }
    }
    false : {
      $lv_require = []
    }
  }
  package {
    ["cdr-archiver-cbv1", "cdr-archiver-cbv2"]:
      ensure => present,
      require => File["/var/lib/cdr-archiver"];
  }
  file {
    "/data/cdr_archiver":
      owner => taxman-daemons, group => taxman-daemons, mode => 750,
      require => $lv_require,
      ensure => directory;
    "/var/lib/cdr-archiver":
      ensure => link,
      target => "/data/cdr_archiver";
  }
  host_file {
    "/etc/default/cdr-archiver-cbv1": mode => 644;
    "/etc/default/cdr-archiver-cbv2": mode => 644;
  }

}

class erp_1_0::taxman-web (
$environment = "development",
$taxman_pg_host = "127.0.0.1",
$taxman_pg_pool_size = "16",
$mongo_bind_address = "127.0.0.1",
$enable_mongodb = true,
$amq_voip_1_host = "",
$amq_voip_1_port = "61613",
$amq_voip_1_queues = "",
$amq_voip_2_host = $amq_voip_1_host,
$amq_voip_2_port = "61613",
$amq_voip_2_queues = "",
$amq_voip_user = "",
$amq_voip_passwd = "",
$amq_taxerp_1_host,
$amq_taxerp_1_port = "61613",
$amq_taxerp_2_host = $amq_taxerp_1_host,
$amq_taxerp_2_port = "61613",
$amq_taxerp_user,
$amq_taxerp_passwd,
$amq_taxerp_queues,
$webserver_taxman = false
) {
  erp_1_0::rails_app {
    "taxman-web":
      uid     => "1018",
      gid     => "1018",
      environment => $environment,
      ruby_version=> "jruby-1.7.1",
      unicorn_start=> false,
      bind_address => $bind_address,
      bind_port => $bind_port,
      profile => "export RAILS_ENV=$environment\nexport JRUBY_OPTS=\"-J-XX:PermSize=256M -J-XX:MaxPermSize=512M -J-Xmn1024m -J-Xms2048m -J-Xmx2048m\"" ,
  }

  $monit_conf_alert_email = $monit::monit_conf_alert_email

  monit_1_0::monit::monit_file {
    "taxman-web":
      requires => [Package["taxman-web"]];
  }

  file {
    "/data/grid_sets":
      owner => taxman-web, group => taxman-web, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/call_logs":
      owner => taxman-web, group => taxman-web, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/accounting":
      owner => taxman-web, group => taxman-web, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/archives":
      owner => taxman-web, group => taxman-web, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/vno_journals":
      owner => taxman-web, group => taxman-web, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/csv_reports":
      owner => taxman-web, group => taxman-web, mode => 755,
      require => $lv_require,
      ensure => directory;
    "/data/mobile_batches":
      owner => taxman-web, group => taxman-web, mode => 750,
      require => $lv_require,
      ensure => directory;
    "/data/sfr":
      owner => taxman-web, group => taxman-web, mode => 750,
      require => $lv_require,
      ensure => directory;
#    "/data/sfr/tickets":
#      owner => taxman-web, group => taxman-web, mode => 750,
#      require => $lv_require,
#      ensure => directory;
    "/data/exports":
      owner => taxman-web, group => taxman-web, mode => 750,
      require => $lv_require,
      ensure => directory;
  }

  file {
    "/opt/local/bin/ticketvalues.sh":
      owner => root, group => root, mode => 755,
      content => template('erp_1_0/taxman/ticketvalues.sh.erb');
  }

  file {
    "/srv/taxman-web/config/configuration.yml":
      owner => taxman-web, group => taxman-web, mode => 660,
      content => template('erp_1_0/taxman-common/configuration.yml.erb'),
      require => Package["taxman-web"];
    "/srv/taxman-web/config/database.yml":
      owner => taxman-web, group => taxman-web, mode => 660,
      content => template('erp_1_0/taxman-common/database.yml.erb'),
      require => Package["taxman-web"];
  }
  file {
    "/srv/taxman-web/config/mongoid.yml":
      owner => taxman-web, group => taxman-web, mode => 660,
      content => template('erp_1_0/taxman-common/mongoid.yml.erb'),
      require => Package["taxman-web"];
  }

#  case $webserver_taxman {
#    true : {
#      file {
#        "/etc/nginx/sites-enabled/taxman":
#          owner => root, group => root, mode => 755,
#          content => template('erp_1_0/taxman/taxman.nginx.erb'),
#          require => Package["nginx"];
#        # unicorn log
#        "/var/log/taxman":
#          owner => taxman, group => taxman, mode => 750,
#          ensure => directory;
#        "/etc/logrotate.d/unicorn-taxman":
#          owner => root, group => root, mode => 644,
#          source => "${files_root}/erp_1_0/taxman/unicorn-taxman-logrotate",
#          notify => Service["monit"],
#          require => [Package["monit"]];
#      }
#      package {
#        "nginx":
#          ensure => present;
#      }
#    }
#  }
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


}
