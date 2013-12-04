#modules lamp_1_0

class lamp_1_0::lamp_1_0 {
  case $vsftpd_banner {'': { $vsftpd_banner = true } }
  include apache
  include mysql_1_0::mysql
  include vsftpd::lamp

  # Param ftp
  file {
    "/etc/vsftpd.conf":
      owner => root, group => root, mode => 600,
      content => template("lamp_1_0/vsftpd.conf.erb"),
      before => Service["vsftpd"],
      require => Package["vsftpd"];
    "/etc/vsftpd_login.db.txt":
      content => template("lamp_1_0/vsftpd_login.db.txt.erb"),
      owner => root, group => root, mode => 600,
      before => Service["vsftpd"],
      require => Package["db4.6-util","vsftpd"];
  }
  exec {
    "create_ftp_usrdb":
      command => "db4.6_load -T -t hash -f /etc/vsftpd_login.db.txt /etc/vsftpd_login.db",
      require => File["/etc/vsftpd_login.db.txt"]
  }
  package {
    ["php5-mysql",
    "php5-gd"]:
      ensure => present;
  }
  package {
    "libapache2-mod-php5":
      ensure => present;
  }
  apache_module {
    "php5":
      require_package => "libapache2-mod-php5",
      ensure => present;
    "rewrite":
      ensure => present;
  }

  define create_site ($username, $password, $servername, $vhostalias, $joomla_adm_ip='') {
    file {
      "/var/www/${name}":
        owner => www-data, group => www-data, mode => 775,
        ensure => directory;
      "/var/www/${name}/www":
        owner => www-data, group => www-data, mode => 775,
        ensure => directory,
        require => File["/var/www/${name}"];
      "/var/www/${name}/logs":
        owner => www-data, group => www-data, mode => 775,
        ensure => directory,
        require => File["/var/www/${name}"];
      "/var/www/${name}/tmp":
        owner => www-data, group => www-data, mode => 775,
        ensure => directory,
        require => File["/var/www/${name}"];
    }
    apache_virtual_server {
      "${name}":
        document_root => "/var/www/${name}/www",
        require => File["/var/www/${name}"],
        content => template("lamp_1_0/site.erb");
    }
    # Creation de l'utilisateur et de la base mysql
    mysql_1_0::mysql::mysql_db {
      "${name}":
        username => $username,
        password => $password;
    }
  }
}
