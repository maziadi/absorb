#
# Classe pour une passerelle VOIP
#
# Inclut: opensips, mysql
# Paramètres:
#  $opensips_default_tree: arbre de routage CR par defaut
#  $opensips_db_password: mot de passe de la base de donnees OpenSIPS 
#  $opensips_db_erp_password: mot de passe de la base de donnees OpenSIPS pour l'utilisateur erp (si pas defini, utilisateur pas cree)
#  $opensips_db_ro_password: mot de passe de la base de donnees OpenSIPS pour un acces en lecture seule 
# OPTIONNEL
#  $opensips_port: port d'ecoute du serveur par defaut 5060
#  $opensips_service_addr: ip de service specifique opensips. Si pas defini, $service_addr est utilise
#  $slony1_databases: bases de données (postgres) à répliquer entre le master et le slave
#
class voip_2_1::pcscf-c5 (
$opensips_db_erp_password = false,
$opensips_port  = '5060',
$opensips_cfg_template = 'opensips-c5.cfg.erb',
$opensips_service_addr = $service_addr,
$postgresql_bind_address = '127.0.0.1',
$postgresql_listen_address = '',
$postgresql_trusted_addresses = [],
$postgresql_max_connections = 600,
$pcscf_is_a_backup = false,
$opensips_db_user = 'opensips',
$slony1_databases = ['opensips'],
$monit_other_partition = []
){

  class {
    "postgresql_1_0::server":
      version => '8.4',
      postgresql_max_connections => $postgresql_max_connections,
      listen => $postgresql_listen_address;
  }
  class {
    "postgresql_1_0::client":
      version => '8.4',
  }

  sysctl { "kernel.shmmax" : value => "134217728" }
  sysctl { "net.ipv4.ip_forward": }

  package { 
    ["opensips", 
     "opensips-carrierroute-module", 
     "opensips-postgres-module", 
     "opensips-snmpstats-module"
    ]: 
      ensure => present,
      before => File["/etc/opensips/opensips.cfg"];
    ["mediaproxy-dispatcher",
     "mediaproxy-relay",
    ]:
      ensure => present,
      before => [File["/etc/mediaproxy/config.ini"],File["/etc/mediaproxy/tls"]];
  }

  replace { enable_opensips:
    file => "/etc/default/opensips",
    pattern => ".*RUN_OPENSIPS=no.*",
    replacement => "RUN_OPENSIPS=yes",
    require => Package["opensips"],
    before => Service["opensips"];
  }

  cron {
    "monitor_gw_status":
      command => "/usr/bin/monitor_gw_status",
      user => root,
      minute => "*/1",
  }

  file {
    "/etc/opensips/opensips.cfg": 
      owner => root, group => root, mode => 640,  
      content => template("voip_2_1/pcscf/${opensips_cfg_template}"),
      require => Package["opensips"],
      before => Service["opensips"]; 
    "/etc/opensips/opensipsctlrc": 
      owner => root, group => root, mode => 644,  
      content => template("voip_2_1/pcscf/opensipsctlrc.erb"), 
      require => Package["opensips"],
      before => Service["opensips"];
    "/etc/mediaproxy/config.ini":
      owner => root, group => root, mode => 640,
      content => template("voip_2_1/mediaproxy/config.ini.erb"),
      require => [Package["mediaproxy-relay"], Package["mediaproxy-dispatcher"]],
      before => [Service["mediaproxy-relay"], Service["mediaproxy-dispatcher"]];
    "/etc/mediaproxy/tls":
      owner => root, group => root, mode => 600,
      ensure => directory,
      recurse => true,
      source => [
        "${dist_files}/nodes/${hostname}/etc/mediaproxy/tls",
        "${files_root}/voip_2_1/pcscf/etc/mediaproxy/tls"
      ],
      require => [Package["mediaproxy-relay"], Package["mediaproxy-dispatcher"]],
      before => [Service["mediaproxy-relay"], Service["mediaproxy-dispatcher"]];
  }

  service {	
    "opensips":
      enable => true,
      ensure  => running,
      hasrestart => true,
      pattern => '/opensips';
    "mediaproxy-dispatcher":
      enable => true,
      ensure => running,
      hasrestart => true,
      pattern => '/media-dispatcher',
      subscribe => [File["/etc/mediaproxy/tls"], File["/etc/mediaproxy/config.ini"]];
    "mediaproxy-relay":
      enable => true,
      ensure => running,
      hasrestart => true,
      pattern => '/media-relay',
      subscribe => [File["/etc/mediaproxy/tls"], File["/etc/mediaproxy/config.ini"]];
  }

  file {
    "/usr/share/opensips/postgres/acc-customize.sql":
      owner => root, group => root, mode => 644,
      ensure => present,
      content => "ALTER TABLE acc ADD from_uri VARCHAR( 64 ) NOT NULL;
ALTER TABLE acc ADD to_uri VARCHAR( 64 ) NOT NULL;
ALTER TABLE acc ADD account_code VARCHAR( 16 ) NOT NULL;
ALTER TABLE acc ADD carrier_code VARCHAR( 64 ) NOT NULL;",
      require => Package["opensips-postgres-module"];
    "/usr/share/opensips/postgres/drouting-customize.sql":
      owner => root, group => root, mode => 644,
      ensure => present,
      content => "ALTER TABLE dr_carriers ADD update_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE dr_rules ALTER timerec SET DEFAULT '';",
      require => Package["opensips-postgres-module"];
    "/usr/share/opensips/postgres/subscriber-customize.sql":
      owner => root, group => root, mode => 644,
      ensure => present,
      content => "ALTER TABLE subscriber ADD group_id INTEGER default 1 NOT NULL;",
      require => Package["opensips-postgres-module"];
    "/opt/local/share/prov-hss":
      owner => root, group => root, mode => 755,  
      ensure => directory;
    "/opt/local/share/prov-hss/prov-hss.sql":
      owner => root, group => root, mode => 644,
      content => "CREATE TABLE account (
account_code varchar(15) PRIMARY KEY NOT NULL,
update_date timestamp NOT NULL default CURRENT_TIMESTAMP
);",
      require => File["/opt/local/share/prov-hss"];
    "/opt/local/bin/cluster_setup.sh":
      owner => root, group => root, mode => 755,  
      ensure => present,
      content => template("voip_2_1/pcscf/cluster_setup.sh.erb");
    "/opt/local/share/gateways_status.sql":
      owner => root, group => root, mode => 644,
      content => "CREATE TABLE gateways_status (
id SERIAL PRIMARY KEY NOT NULL,
address VARCHAR(128) NOT NULL,
status VARCHAR(12) NOT NULL DEFAULT 'unknown',
previous_status VARCHAR(12) NOT NULL DEFAULT 'unknown',
last_modified TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
CONSTRAINT gateways_status_idx UNIQUE (address)
);";
  }
  if $pcscf_is_a_backup {
    file {
      "/opt/local/bin/subscribe.sh":
        owner => root, group => root, mode => 755,  
        ensure => present,
        content => template("voip_2_1/pcscf/subscribe.sh.erb");
      "/opt/local/bin/unsubscribe.sh":
        owner => root, group => root, mode => 755,  
        ensure => present,
        content => template("voip_2_1/pcscf/unsubscribe.sh.erb");
      "/etc/init.d/slony1_update_lock_file":
        owner => root, group => root, mode => 755,
        ensure => present,
        require => Package["slony1-2-bin"];
    }
    exec { "enable_slony1_update_lock_file_in_rc?.d":
      command => "/usr/sbin/update-rc.d slony1_update_lock_file defaults",
      onlyif => "test ! -f /etc/rc2.d/S*slony1_update_lock_file", #Debian starts services in runlevel 2
      require => File["/etc/init.d/slony1_update_lock_file"];
    }
  }

  postgresql_1_0::db {
    "opensips":
      password => $opensips_db_password,
    	owner    => $opensips_db_user,
      require => Package["postgresql-8.4"];
  }

  postgresql_1_0::schema {
    "version table":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/standard-create.sql',
      check_table => 'version',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Package["postgresql-8.4"]];
    "permissions tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/permissions-create.sql',
      check_table => 'address',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "carrier-route tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/carrierroute-create.sql',
      check_table => 'carrierroute',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "drouting tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/drouting-create.sql',
      check_table => 'dr_rules',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "acc tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/acc-create.sql',
      check_table => 'acc',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "drouting customization":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/drouting-customize.sql',
      check_table => 'dr_carriers',
      check_column => 'update_date',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], File["/usr/share/opensips/postgres/drouting-customize.sql"], Postgresql_1_0::Schema["acc tables"], Package["postgresql-8.4"]];
    "acc tables customization":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/acc-customize.sql',
      check_table => 'acc',
      check_column => 'from_uri',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], File["/usr/share/opensips/postgres/acc-customize.sql"], Postgresql_1_0::Schema["acc tables"], Package["postgresql-8.4"]];
    "domain tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/domain-create.sql',
      check_table => 'domain',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "subscriber tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/auth_db-create.sql',
      check_table => 'subscriber',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "subscriber tables customization":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/subscriber-customize.sql',
      check_table => 'subscriber',
      check_column => 'group_id',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], File["/usr/share/opensips/postgres/subscriber-customize.sql"], Postgresql_1_0::Schema["subscriber tables"], Package["postgresql-8.4"]];
  	"usrloc tables":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/usr/share/opensips/postgres/usrloc-create.sql',
      check_table => 'location',
      require => [Postgresql_1_0::Db["opensips"], Package["opensips-postgres-module"], Postgresql_1_0::Schema["version table"], Package["postgresql-8.4"]];
    "account table":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/opt/local/share/prov-hss/prov-hss.sql',
      check_table => 'account',
      check_column => 'account_code',
      require => [Postgresql_1_0::Db["opensips"], File["/opt/local/share/prov-hss/prov-hss.sql"], Package["postgresql-8.4"]];
    "gateways_status table":
      db => 'opensips', username => $opensips_db_user, password => $opensips_db_password,
      file => '/opt/local/share/gateways_status.sql',
      check_table => 'gateways_status',
      check_column => 'address',
      require => [Postgresql_1_0::Db["opensips"], File["/opt/local/share/gateways_status.sql"], Package["postgresql-8.4"]];
  }
  file {
    "/usr/share/opensips/postgres/carrierroute-create.sql":
      owner => root, group => root, mode => 755,
      ensure => present,
      source => "${files_root}/voip_2_1/pcscf/usr/share/opensips/postgres/carrierroute-create.sql",
      require => Package["opensips-postgres-module"],
      before => [Service["opensips"], Postgresql_1_0::Schema["carrier-route tables"]];
  }

  class {
      "monit_1_0::monit":
        monit_other_partition => $monit_other_partition; 
  } 
 
  monit_1_0::monit::monit_file {
     "opensips":
       requires => Package["opensips"];
  }

  file {
    "/root/screenrc":
      owner => root, group => root, mode => 640,
      source => "${files_root}/voip_2_1/pcscf/root/screenrc";
    "/var/lib/postgresql/.psqlrc":
      owner => postgres, group => postgres, mode => 640,
      source => "${files_root}/voip_2_1/pcscf/var/lib/postgresql/psqlrc",
      require => Package["postgresql-8.4"];
  }

  package {
    "slony1-2-bin":
      ensure => present;
    "postgresql-8.4-slony1-2":
      ensure => present;
  }

  file {
    "/etc/slony1":
      owner => postgres, group => postgres, mode => 755,
      ensure => directory,
      require => Package["slony1-2-bin"];
    "/etc/slony1/slon_tools.conf":
      owner => postgres, group => postgres, mode => 644,
      source => [
        "${dist_files}/nodes/${hostname}/etc/slony1/slon_tools.conf",
        "${files_root}/voip_2_1/pcscf/etc/slony1/slon_tools.conf"
      ],
      require => Package["slony1-2-bin"];
    "/etc/slony1/opensips":
      owner => postgres, group => postgres, mode => 750,
      ensure => directory,
      require => Package["slony1-2-bin"];
    "/etc/slony1/opensips/slon.conf":
      owner => postgres, group => postgres, mode => 640,
      content => template("voip_2_1/pcscf/etc/slony1/opensips/slon.conf"),
      require => Package["slony1-2-bin"];
    "/var/log/slony1":
      owner => postgres, group => postgres, mode => 750,
      ensure => directory,
      require => Package["slony1-2-bin"];
  }

  exec { "disable_slony1_from_rc?.d":
    command => "/usr/sbin/update-rc.d slony1 disable",
    onlyif => "test -f /etc/rc2.d/S*slony1 || test -f /etc/rc3.d/S*slony1 || test -f /etc/rc4.d/S*slony1 || test -f /etc/rc5.d/S*slony1",
    require => Package["slony1-2-bin"];
  }

  monit_1_0::monit::monit_file {
     "slony1":
       requires => Package["slony1-2-bin"];
  }

  # Tools

  package {
    ["pcscf-tools"]:
      ensure => present;
  }

  file {
    "/opt/local/bin/report_gw_disabled.sh":
      owner => root, group => root, mode => 755,
      content => template("voip_2_1/pcscf/report_gw_disabled.sh.erb");
    "/etc/voip-tools.yaml":
      owner => root, group => root, mode => 640,
      content => template("voip_2_1/pcscf/voip-tools.yaml.erb"),
      require => Package["pcscf-tools"];
  }
}
