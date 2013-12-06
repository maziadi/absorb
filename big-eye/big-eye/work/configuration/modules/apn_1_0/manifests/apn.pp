class apn_1_0::apn (
$env,                     # development, preproduction or production
$rad_db_trusted=[],       # trusted db addresses, /32
$pg_rt_trusted=[],        # trusted router addresses, /32
$hb_ucasts=[],            # heartbeat ucasts : "interface nodeIP" form, second server
$hb_cluster_nodes=[],     # heartbeat nodes : node1, node2
$db_primary=false,        # is the local db default primary ? DEPRECATED
$pg_replicate_ip='',      # second DB IP
$virtual_ip='',           # virtual IP on the master node, switched during failover
$slash_virtual_ip,        # slash of virtual IP
$tax_ip_port,             # TAXATION server:port
$pasdaran_ip,             # PASDARAN service ip
$pasdaran_1_ip,           # PASDARAN server 1
$pasdaran_2_ip,           # PASDARAN server 2
$basij_ip,                # BASIJ server
$ggsn_ip1,                # GGSN 1 IP
$ggsn_ip2,                # GGSN 2 IP
$prov_install=false,      # install APN provisionning ?
$amq_user='',             # if prov_install, AMQ user
$amq_passwd='',           # if prov_install, AMQ passwd
$amq_ip='',               # if prov_install, AMQ server IP
$amq_queue=''             # if prov_install, AMQ queue, node is the hostname
) {

  $db_name = "radius"
  $db_user = "radius"
  $db_passwd = "radius"
  $pg_version= "9.1"
  $db_type = "postgresql"

#
# Freeradius with Postgresql
#

  package {
    "postgresql-${pg_version}-plsh":
      ensure => present;
    "curl":
      ensure => present;
  }

  sysctl {       
    "kernel.shmmax":
      value => "2147483648";
  } 

  class {
    "freeradius_1_0::freeradius":
      auth => "PAP",
      use_db => true,
      db_type => $db_type,
      db_auth => true,
      db_acct => true,
      db_listen => "*",
      db_server => $virtual_ip,
      db_trusted => $rad_db_trusted,
      db_name => $db_name,
      db_user => $db_user,
      db_passwd => $db_passwd,
      db_autostart => false,
      log2syslog => true,
      log_details => true,
      path_sqlconf => "apn_1_0/freeradius",
      path_pgconf => "apn_1_0/postgresql";
  }

  exec {
    "initdb":
      command => "/usr/lib/postgresql/${pg_version}/bin/initdb -D /var/lib/postgresql/${pg_version}/main", 
      user => postgres,
      unless => "[ \"$(ls -A /var/lib/postgresql/${pg_version}/main)\" ] || false",
      require => [Package["postgresql-${pg_version}-plsh"], Package["freeradius"]];
    "permspg":
      command => "/bin/chmod 700 /var/lib/postgresql/${pg_version}/main", 
      require => Exec["initdb"];
    "mkdir":
      command => "/bin/mkdir -p /data/apn";
  }

  file {
    "/var/lib/postgresql/${pg_version}/main/postgresql.conf":
      owner => postgres, group => postgres, mode => 644,
      content => template("apn_1_0/postgresql/postgresql.conf"),
      require => Exec["initdb"];
    "/etc/postgresql/${pg_version}/main/postgresql.conf.standby":
      owner => postgres, group => postgres, mode => 644,
      content => template("apn_1_0/postgresql/postgresql.conf.standby"),
      require => Exec["initdb"];
    "/var/lib/postgresql/${pg_version}/main/recovery.conf":
      owner => postgres, group => postgres, mode => 644,
      content => template("apn_1_0/postgresql/recovery.conf.erb"),
      require => Exec["initdb"];

    "/var/lib/postgresql/primary2standby.sh":
      owner => postgres, group => postgres, mode => 755,
      content => template("apn_1_0/postgresql/primary2standby.sh.erb"),
      require => Exec["initdb"];

    "/etc/freeradius/sql/postgresql/functions.sql":
      owner => root, group => root, mode => 644,
      content => template("apn_1_0/sql/functions.sql.erb"),
      require => Package["freeradius-postgresql"];
    "/etc/freeradius/sql/postgresql/schema_add.sql":
      owner => root, group => root, mode => 644,
      content => template("apn_1_0/sql/schema_add.sql.erb"),
      require => Package["freeradius-postgresql"];
    "/etc/freeradius/hints":
      owner => root, group => root, mode => 644,
      content => template("apn_1_0/freeradius/hints.erb"),
  }

  exec {
    "copyconf":
      # for the use of pg_ctlcluster (pg_ctl debian wrapper)
      command => "/bin/cp /var/lib/postgresql/${pg_version}/main/recovery.conf /etc/postgresql/${pg_version}/main",
      require => File["/var/lib/postgresql/${pg_version}/main/recovery.conf"];
  }

#
# Heartbeat
#

  class {
    "ha_3_0::heartbeat":
      ucasts => $hb_ucasts,
      cluster_nodes => $hb_cluster_nodes;
  }

  file {
    "/etc/ha.d/haresources":
      owner => root, group => root, mode => 644,
      content => template("apn_1_0/hb/haresources.erb"),
      require => Package["heartbeat"];
    "/etc/ha.d/resource.d/PostgreFailover":
      source => "${files_root}/apn_1_0/etc/ha.d/resource.d/PostgreFailover",
      mode => 755, owner => root, group => root,
      require => Package["heartbeat"];
  }

#
# Prov-apn (zepar)
#

  if $prov_install {
    package {
      "prov-apn":
        ensure => present;
    }

    file {
      "/etc/default/prov-apn":
        owner => root, group => root, mode => 644,
        content => template("apn_1_0/provapn/prov-apn.erb"),
        require => Package["prov-apn"];
    }

    class {
      "monit_1_0::monit":;
    }

    monit_1_0::monit::monit_file {
      "prov-apn":
        require => Package['prov-apn'];
    }

  }

#
# Scripts & crons
#

  package {
    "ruby-sequel":
      ensure => present;
    "ruby-sequel-pg":
      ensure => present;
    "ruby-cmdparse":
      ensure => present;
  }

  file {
    "/opt/local/bin/rad-auth.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/rad-auth.sh.erb");
    "/opt/local/bin/rad-acctstop.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/rad-acctstop.sh.erb");
    "/opt/local/bin/frd-update.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/frd-update.sh.erb");
    "/opt/local/bin/lib-apn.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/lib-apn.sh.erb");
    "/opt/local/bin/archive.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/archive.sh.erb");
    "/opt/local/bin/report-unsent.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/report-unsent.sh.erb");
    "/opt/local/bin/report-unstopped.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/report-unstopped.sh.erb");
    "/opt/local/bin/delete-acct.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/delete-acct.sh.erb");
    "/opt/local/bin/closesession.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/closesession.sh.erb");
    "/opt/local/bin/unclosedsessions.sh":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/unclosedsessions.sh.erb");
    "/opt/local/bin/apn-mon":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/apn-mon.erb");
    "/opt/local/bin/mib-apn":
      owner => root, group => root, mode => 755,
      content => template("apn_1_0/scripts/mib-apn.erb");
    "/opt/local/bin/rtapnprov":
      owner => root, group => root, mode => 755,
      require => [Package["ruby-sequel"], Package["ruby-sequel-pg"], Package["ruby-cmdparse"]],
      content => template("apn_1_0/provapn/rtapnprov.erb");
  }

  if $env != "production" {
    package {
      "ruby-sinatra": 
        ensure => present;
      "dstat":
        ensure => present;
    }
    file {
      "/opt/local/bin/beaujolais.rb":                             # taxation server can be locally simulated
        owner => root, group => root, mode => 755,
        require => Package['ruby-sinatra'],
        content => template("apn_1_0/scripts/beaujolais.rb.erb");
    }
  }

  cron {
    "archive":
      command => "/opt/local/bin/archive.sh",
      user    => root,
      monthday =>['1','8','15','22'],
      hour    => 0,
      minute  => 0,
      ensure  => present,
      require => File["/opt/local/bin/archive.sh"];
    "report-unsent":
      command => "/opt/local/bin/report-unsent.sh nodelay",
      user    => root,
      hour    => '*/1',
      minute  => 0,
      ensure  => present,
      require => File["/opt/local/bin/report-unsent.sh"];
    "report-unstopped":
      command => "/opt/local/bin/report-unstopped.sh",
      user    => root,
      hour    => '*/1',
      minute  => 0,
      ensure  => present,
      require => File["/opt/local/bin/report-unstopped.sh"];
    "delete-acct":
      command => "/opt/local/bin/delete-acct.sh",
      user    => root,
      hour    => 1,
      minute  => 0,
      ensure  => present,
      require => File["/opt/local/bin/delete-acct.sh"];
  }

}
