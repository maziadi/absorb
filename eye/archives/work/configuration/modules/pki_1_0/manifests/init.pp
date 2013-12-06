#modules pki_1.0
class pki::base {
  file {
    [ 
      "/data/pki",
      "/data/pki/ca_root",
      "/data/pki/ca_root/keys",
      "/data/pki/ca_vpnssl",
      "/data/pki/ca_vpnssl/keys",
      "/data/pki/ca_erp",
      "/data/pki/ca_erp/keys",
    ]:
      ensure => directory,
      mode => 750, owner => root, group => root;
    "/opt/local/bin/inherit-inter":
      source => "${files_root}/pki_1_0/inherit-inter",
      mode => 740, owner => root, group => root;
    "/opt/local/bin/revoke-full":
      source => "${files_root}/pki_1_0/revoke-full",
      mode => 740, owner => root, group => root;
    "/opt/local/bin/pkitool":
      source => "${files_root}/pki_1_0/pkitool",
      mode => 740, owner => root, group => root;
  }
  package {
    "libpkiprov-ruby1.8": ensure => present;
  }

  include monit
  $monit_conf_alert_email = $monit::monit_conf_alert_email

  file {
    "/etc/monitrc.d/pkiprov":
      owner => root, group => root, mode => 700,
            content => template("monit/pkiprov.erb"),
            notify => Service["monit"],
            require => Package["monit"]
  }
}
