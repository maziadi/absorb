
#
# VARIABLES:
# mysql_root_password (default)
# mysql_create_lv (default)
# mysql_vg_name (default)
#
class mysql_1_0::mysql {
  case $mysql_root_password { '': { $mysql_root_password = "Ikta2429" } }
  case $mysql_create_lv { '': { $mysql_create_lv = false } }
  case $mysql_vg_name { '': { $mysql_vg_name = "data" } }
  # Variables pour my.cnf
  case $mysql_key_buffer {'': { $mysql_key_buffer = '16' } }
  case $mysql_thread_stack {'': { $mysql_thread_stack = '128' } }
  case $isamchk_key_buffer {'': { $isamchk_key_buffer = '16' } }
  case $mysql_bind_address {'': { $mysql_bind_address = '127.0.0.1' } }
  case $mysql_query_cache_limit {'': { $mysql_query_cache_limit = '1' } }
  case $mysql_query_cache_size {'': { $mysql_query_cache_size = '16' } }
  case $mysql_expire_logs_days {'': { $mysql_expire_logs_days = "10" } }
  case $mysql_max_binlog_size {'': { $mysql_max_binlog_size = "100M" } }
  case $mysql_logbin {'': { $mysql_logbin = false } }
  case $mysql_log {'': { $mysql_log = false } }
  case $mysql_replication {'': { $mysql_replication = false } }
  case $mysql_max_connections {'': { $mysql_max_connections = false } }
  case $mysql_myisam_sort_buffer_size {'': { $mysql_myisam_sort_buffer_size = false } }

  # compatibility check
  if $operatingsystemrelease == "4.0" {
    fail("module mysql_1_0 doesn't support etch\n")
  }

  if $do_not_create_lv == true {
    fail("do_not_create_lv is deprecated, please use mysql_create_lv\n")
  }

  define mysql_db($username, $password, $init_file = '') {
    $create_cmd = $init_file ? {
      '' => "mysqladmin -uroot -p${mysql::mysql_root_password} CREATE '${name}'", 
      default => "mysqladmin -uroot -p${mysql::mysql_root_password} CREATE '${name}'; mysql -uroot -p${mysql::mysql_root_password} -BN '${name}' < ${init_file}"
    }
    exec { "create mysql db ${name}":
      command => $create_cmd, 
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'SHOW DATABASES' | grep '^${name}$'",
      require => [ Package["mysql-server"], Exec["Set MySQL server root password"]]
    }
    exec { "grant all privileges on ${name} to ${username}@localhost":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ALL PRIVILEGES ON `${name}`.* TO `${username}`@`localhost` IDENTIFIED BY \"${password}\"'",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.db where mysql.db.db=\"${name}\" and mysql.db.host=\"localhost\"' | grep '^${username}@localhost$'",
      require => Exec["create mysql db ${name}"]
    }
    exec { "grant all privileges on ${name} to ${username}@%":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ALL PRIVILEGES ON `${name}`.* TO `${username}`@`%` IDENTIFIED BY \"${password}\"'",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.db where mysql.db.db=\"${name}\" and mysql.db.host=\"%\"' | grep '^${username}@%$'",
      require => Exec["create mysql db ${name}"]
    }
  }

  define mysql_user($db, $password, $privileges = 'ALL PRIVILEGES', $bypass = false) {
    case $bypass {
      false: {
        exec { "grant ${privileges} on ${db} to ${name}@localhost":
          command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ${privileges} ON `${db}`.* TO `${name}`@`localhost` IDENTIFIED BY \"${password}\"'",
          unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.db where mysql.db.db=\"${db}\" and mysql.db.host=\"localhost\"' | grep '^${name}@localhost$'",
          require => Exec["create mysql db ${db}"]
        }
        exec { "grant ${privileges} on ${db} to ${name}@%":
          command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ${privileges} ON `${db}`.* TO `${name}`@`%` IDENTIFIED BY \"${password}\"'",
          unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.db where mysql.db.db=\"${db}\" and mysql.db.host=\"%\"' | grep '^${name}@%$'",
          require => Exec["create mysql db ${db}"]
        }
      }
      true: {
        exec { "grant ${privileges} on ${db} to ${name}@localhost":
          command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ${privileges} ON `${db}`.* TO `${name}`@`localhost` IDENTIFIED BY \"${password}\"'",
          unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.db where mysql.db.db=\"${db}\" and mysql.db.host=\"localhost\"' | grep '^${name}@localhost$'";
        }
        exec { "grant ${privileges} on ${db} to ${name}@%":
          command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ${privileges} ON `${db}`.* TO `${name}`@`%` IDENTIFIED BY \"${password}\"'",
          unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.db where mysql.db.db=\"${db}\" and mysql.db.host=\"%\"' | grep '^${name}@%$'";
        }
      }
    }
  }

  define mysql_global_grant($privileges = 'ALL') {
    exec { "grant ${privileges} on *.* to ${name}@localhost":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ${privileges} ON *.* TO `${name}`@`localhost`'",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select ${privileges}_priv from mysql.user where mysql.user.user=\"${name}\" and mysql.user.host=\"localhost\"' | grep '^Y$'"
    }
    exec { "grant ${privileges} on *.* to ${name}@%":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ${privileges} ON *.* TO `${name}`@`%`'",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select ${privileges}_priv from mysql.user where mysql.user.user=\"${name}\" and mysql.user.host=\"%\"' | grep '^Y$'"
    }
  }

  define mysql_schema($db, $username, $password, $file, $check_table, $check_column = '') {
    $check_cmd = $check_column ? {
      '' => "mysql -nb -uroot -p${mysql::mysql_root_password} '${db}' -e 'show create table `${check_table}`'",
      'table engine InnoDB' => "mysql -nb -uroot -p${mysql::mysql_root_password} '${db}' -e 'show create table `${check_table}`' | grep -qi ' ENGINE=InnoDB '",
      default => "mysql -NB -uroot -p${mysql::mysql_root_password} '${db}' -e 'DESCRIBE `${check_table}`' | grep -q '^${check_column}'" 
    }
    exec { "$name":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN '${db}' < ${file}", 
      unless => $check_cmd, 
      require => [Package["mysql-server"], Exec["create mysql db ${db}"]]
    }
  }

  package { "mysql-server": 
    ensure => present,
  }
  service {
    "mysql":
    enable => true,
    ensure => running,
    subscribe => File["/etc/mysql/my.cnf"],
  }
  file { 
    "/etc/mysql/my.cnf":
      owner => root, group => root, mode => 644,
      content => template('mysql_1_0/my.cnf.erb'),
      require => Package["mysql-server"];
    "/var/lib/mysql":
      owner  => mysql, group => mysql, mode => 755,
      ensure => directory,
      require => Package["mysql-server"];
  }
  case $mysql_create_lv {
    true : {
      file {
        "/opt/local/bin/create-mysql-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/mysql_1_0/create-mysql-lv";
      }

      exec { "Create Mysql LV":
        require => File["/opt/local/bin/create-mysql-lv"],
        unless => "lvdisplay /dev/${mysql_vg_name}/mysql",
        command => "/opt/local/bin/create-mysql-lv",
        before => Package["mysql-server"]
      }
    } 
  }
  exec { "Set MySQL server root password":
#    subscribe => [ Package["mysql-server"] ],
#    refreshonly => true,
    require => Package["mysql-server"],
    unless => "mysqladmin -uroot -p$mysql_root_password status",
    command => "mysqladmin -uroot password $mysql_root_password",
  }
}
