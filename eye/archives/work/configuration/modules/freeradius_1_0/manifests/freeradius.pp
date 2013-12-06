class freeradius_1_0::freeradius (
$auth,                  # PEAP-MSCHAPV2 | PAP | CHAP
$gvrp=false,            # dynamic vlan assignement, static by default
$users_file=true,       # users file manage by puppet or not
$use_db=false,          # use db or file for auth and acct
$db_type='',            # mysql | postgresql
$db_auth=false,         # db authentication ? else users file is used
$db_acct=false,         # db accounting ? else acct to files
$db_listen='*',         # db clients, localhost is automatically included
$db_server='',          # DB server IP
$db_trusted=[],         # trusted addresses, /32
$db_name="radius",      # db name
$db_user="radius",      # db username
$db_passwd="radius",    # db passwd
$db_create=false,       # create db with schema.sql from freeradius-postgresql debian package ?
$db_autostart=true,     # autostart db ?
$rsyslog=false,         # rsyslog server ?
$log2syslog=false,      # log to syslog ?
$log_details=true,      # log auth_log, accouting_details and reply_log ?
$linelog=false,         # linelog module ?
$path_sqlconf="freeradius_1_0", # path to sql.conf template file, used to redefine sql.conf template by potential uphill class
$path_pgconf="postgresql_1_0" # path to pg template files, used to redefine templates by potential uphill class
) {

  package {
    "freeradius":
      ensure => present;
  }

  if $use_db {
    case $db_type {

      'postgresql': {
        package {
        "freeradius-postgresql":
          ensure => present,
          require => Package["freeradius"];
        }

        $postgresql_trusted_addresses = $db_trusted
        class {
          "postgresql_1_0::server":
            listen => $db_listen,
            ssl => false,
            path_pgconf => $path_pgconf;
         }

        $version = $postgresql_1_0::params::version

        if $db_create {
          # create user and db
          postgresql_1_0::db {
            $db_name:
              owner => $db_user,
              password => $db_passwd,
              require => [Package["freeradius"], Package["freeradius-postgresql"], Exec["permsrad"], Exec["permspg"], File["/etc/freeradius/sql/postgresql/schema.sql"]];
          }

          # create radius db default objects
          postgresql_1_0::schema { 
            "default":
              db => $db_name, username => $db_user, password => $db_passwd,
              file => '/etc/freeradius/sql/postgresql/schema.sql',
              check_table => 'radacct',
              require => [Package["freeradius"], Package["freeradius-postgresql"], Exec["permsrad"], File["/etc/freeradius/sql/postgresql/schema.sql"], Postgresql_1_0::Db[$db_name]];
          }
        }
      }
      
      'mysql': {
         package {
           "freeradius-mysql":
           ensure => present,
           require => Package["freeradius"];
        }
      }
    }
  }

  file {
    # logrotate
    "/etc/logrotate.d/freeradius":
      content => template("freeradius_1_0/logrotate.erb"),
      mode => 644, owner => root, group => root;

    # radius configuration
    "/etc/freeradius/radiusd.conf":
      content => template("freeradius_1_0/radiusd.conf.erb"),
      mode => 644, owner => root, group => root,
      require => Package["freeradius"];
    "/etc/freeradius/modules/linelog":
      content => template("freeradius_1_0/linelog.erb"),
      mode => 644, owner => root, group => root,
      require => Package["freeradius"];
    "/etc/freeradius/modules/detail":
      content => template("freeradius_1_0/detail.erb"),
      mode => 644, owner => root, group => root,
      require => Package["freeradius"];
    "/etc/freeradius/modules/detail.log":
      content => template("freeradius_1_0/detail.log.erb"),
      mode => 644, owner => root, group => root,
      require => Package["freeradius"];
    "/etc/freeradius/sites-available/default":
      content => template("freeradius_1_0/site.erb"),
      mode => 644, owner => root, group => root,
      require => [Exec["site"], Package["freeradius"]];
    "/etc/freeradius/sql.conf":
      content => template("${path_sqlconf}/sql.conf.erb"),
      mode => 644, owner => root, group => root,
      require => Package["freeradius"];
  }
  if $users_file {
    file {
      "/etc/freeradius/users":
        content => template("freeradius_1_0/users.erb"),
        mode => 644, owner => root, group => root,
        require => Package["freeradius"];
    }
  }
  if $use_db {
    case $db_type {
      'postgresql': {
         file {
          "/etc/freeradius/sql/postgresql/schema.sql":
            content => template("freeradius_1_0/schema.sql.erb"),
            mode => 644, owner => root, group => freerad,
            require => [Package["freeradius"], Package["freeradius-postgresql"]];
          "/etc/freeradius/sql/postgresql/nas.sql":
            content => template("freeradius_1_0/nas.sql.erb"),
            mode => 644, owner => root, group => freerad,
            require => [Package["freeradius"], Package["freeradius-postgresql"]];
          "/etc/freeradius/sql/postgresql/admin.sql":
            content => template("freeradius_1_0/admin.sql.erb"),
            mode => 644, owner => root, group => freerad,
            require => [Package["freeradius"], Package["freeradius-postgresql"]];
          "/etc/postgresql/${version}/main/start.conf":
            content => template("freeradius_1_0/start.conf.erb"),
            owner => postgres, group => postgres,
            require => [Package["freeradius"], Package["freeradius-postgresql"]];
        }
      }
    }
  }

  exec {
    "site":
    command => "/bin/mv /etc/freeradius/sites-available/default /etc/freeradius/sites-available/default.orig",
    unless => "test -f /etc/freeradius/sites-available/default.orig",
    require => Package["freeradius"];

    "clean_site":
    command => "/bin/rm /etc/freeradius/sites-enabled/inner-tunnel",
    onlyif => "test -f /etc/freeradius/sites-enabled/inner-tunnel",
    require => Package["freeradius"];
  }
  if $use_db {
    case $db_type {
      'postgresql': {
        exec {
          "permsrad":
          command => "/usr/sbin/usermod -a -G freerad postgres",
          require => [Package["freeradius"], Package["freeradius-postgresql"]];
        }
      }
    }
  }

}
