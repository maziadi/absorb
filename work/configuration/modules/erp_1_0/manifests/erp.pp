# Module erp pour l'installation de SI
class erp_1_0::erp (
$environment,
$db_name,
$db_user,
$db_host = 'localhost',
$db_passwd,
$static_url_taxman,
$mail_clockwork,
$mail_sales_summary,
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
$unicorn_workers,
) {

  class {
    "erp_1_0::si_rails_app":
      uid     => "108",
      gid     => "109",
      environment => $environment,
      app_name => "erp",
      ruby_version => "ruby-1.8.7-p358",
      unicorn_workers => $unicorn_workers,
      bind_address => $erp_ip,
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
  }



    include monit

#    Class['nginx_1_0::nginx'] -> Class['erp_1_0::erp']
    $poller_groups=['ticket_modif_group','batch_group','order_group','order_event_group']

    $app_name = "erp"

    user {
      "www-data":
        groups => "erp",
        require => Package["nginx"];
    }

    package {
        [
            "mytop",
            "libmysql-ruby1.8",
            "rake",
        ]: ensure => present;
    }

    config_file {
        "/etc/erp/broker.yml":
            content => template("erp_1_0/erp/broker.yml.erb"),
            require => Package["erp"];
        "/etc/erp/application.yml":
            content => template("erp_1_0/erp/application.yml.erb"),
            require => Package["erp"];
        "/etc/erp/database.yml":
            content => template("erp_1_0/erp/database.yml.erb"),
            require => Package["erp"];
    }

    class {
      "nginx_1_0::nginx":;
    }

    file {
      "/etc/monitrc.d/erp_pollers":
        owner => root, group => root, mode => 700,
        content => template("erp_1_0/erp/monit.erb"),
        notify => Service["monit"],
        require => [Package["monit"],Package["erp"],File["/srv/erp/config/unicorn.rb"]];
      "/etc/monitrc.d/messenger":
        owner => root, group => root, mode => 700,
        content => template("monit_1_0/messenger.erb"),
        notify => Service["monit"],
        require => [Package["monit"],Package["erp"]];
      "/etc/nginx/sites-enabled/extranet-$environment.admin.alphalink.fr":
        owner => root, group => root, mode => 644,
        content=> template("erp_1_0/erp/nginx.erb"),
        require => Package["nginx"];
      "/data/files":
        owner => erp, group => erp, mode => 750,
        ensure => directory,
        require => [User["erp"],Group["erp"]];
      "/data/files/order_document":
        owner => erp, group => erp, mode => 750,
        ensure => directory,
        require => [File["/data/files"]];
      "/data/files/style":
        owner => erp, group => erp, mode => 750,
        ensure => directory,
        require => [File["/data/files"]];
      "/data/files/Tickets":
        owner => erp, group => erp, mode => 750,
        ensure => directory,
        require => [File["/data/files"]];
      "/data/files/tmp":
        owner => erp, group => erp, mode => 750,
        ensure => directory,
        require => [File["/data/files"]];
      "/data/files/batch_eligibility":
        owner => erp, group => erp, mode => 750,
        ensure => directory,
        require => [File["/data/files"]];
      "/srv/erp/public/documents":
        require => [Package["erp"],File["/data/files"]],
        ensure => link,
        target => "/data/files";
      "/etc/logrotate.d/erp":
        owner => root, group => root, mode => 644,
        content => template("erp_1_0/erp/logrotate_erp.erb"),
        require => Package["erp"];
    }

}
