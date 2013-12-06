class collectd_1_0::cgraphz (
$db_user = "",
$db_password = "",
$rrd_data_dir = "/var/lib/collectd/rrd",
$rrdtool = "/usr/bin/rrdtool"
){
  include mysql_1_0::mysql

  mysql_1_0::mysql::mysql_db {
    "cgraphz":
      username => $db_user,
      password => $db_password;
  } ->
  package {
    "mysql-client":
      ensure => present;
    "apache2":
      ensure => present;
    "php5":
      ensure => present;
    "libapache2-mod-php5":
      ensure => present;
    "php5-mysql":
      ensure => present;
    "git":
      ensure => present;
  } ->
  exec {
    "git":
      unless => "test -d /var/www/CGraphz",
      command => "/usr/bin/git clone http://github.com/Poil/CGraphz.git /var/www/CGraphz";
    "mysql":
      require => Exec["git"],
      command => "mysql -u $db_user -p$db_password < /var/www/CGraphz/sql/initial_cgraphz_1.51.sql",
      onlyif => "test -f /var/www/CGraphz/config/config.php.tpl";
    "rm":
      require => Exec["mysql"],
      command => "rm -rf /var/www/CGraphz/config/config.php.tpl",
      onlyif => "test -f /var/www/CGraphz/config/config.php.tpl";
  } ->
  config_file {
    "/var/www/CGraphz/config/config.php" :
      content => template('collectd_1_0/cgraphz.conf.erb');
  } ~>
  service {
    "apache2":
      enable  => true,
      ensure  => running;
  }

}
