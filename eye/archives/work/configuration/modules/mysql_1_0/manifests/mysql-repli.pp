class mysql_1_0::mysql-repli {
  $mysql_logbin = true
  $mysql_replication = true

  # creation de l'utilisateur pour la replication
  define mysql_repli_user($db, $mysql_repli_user, $mysql_repli_pass, $privileges = 'REPLICATION SLAVE') {
    exec { "grant privileges to ${mysql_repli_user}":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e \"GRANT ${privileges} ON *.* TO '${mysql_repli_user}'@'%' IDENTIFIED BY '${mysql_repli_pass}' WITH GRANT OPTION;\"",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.user' | grep '^${mysql_repli_user}@%$'",
    }
  }
  # pour lancer la réplication, utiliser le script suivant
  # pour rsyslog, j'ai coupé la ha et le service rsyslog, sinon les bases sont corrompues
  # sh -x modules/mysql_1_0/files/repli_mysql.sh -m log-1-maquette -s log-2-maquette -u rep_slave -p Eipha8si -b SYSLOG -r Ikta2429
  define mysql_setup_slave_db($username, $password ) {
    $create_cmd = $init_file ? {
      '' => "mysqladmin -uroot -p${mysql::mysql_root_password} create '${name}'",
      default => "mysqladmin -uroot -p${mysql::mysql_root_password} create '${name}';"
    }
    exec { "create mysql db ${name}":
      command => $create_cmd,
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'show databases' | grep '^${name}$'",
      require => [ Package["mysql-server"], Exec["Set MySQL server root password"]]
    }
    exec { "grant user privileges ${name}@localhost":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ALL PRIVILEGES ON ${name}.* to `${username}`@`localhost` identified by \"${password}\"'",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.user' | grep '^${username}@localhost$'",
      require => Exec["create mysql db ${name}"]
    }
    exec { "grant user privileges ${name}":
      command => "mysql -uroot -p${mysql::mysql_root_password} -BN -e 'GRANT ALL PRIVILEGES ON ${name}.* to `${username}`@`%` identified by \"${password}\"'",
      unless => "mysql -uroot -p${mysql::mysql_root_password} -BN -e  'select concat(user,\"@\", host) from mysql.user' | grep '^${username}@%$'",
      require => Exec["create mysql db ${name}"]
    }
  }
  file {
    "/etc/heartbeat/resource.d/promote_master" :
      owner => root, group => root, mode => 755,
      source => "${files_root}/mysql_1_0/promote_master";
    "/opt/local/bin/promote_slave" :
      owner => root, group => root, mode => 755,
      source => "${files_root}/mysql_1_0/promote_slave";
  }
  include mysql_1_0::mysql
}
