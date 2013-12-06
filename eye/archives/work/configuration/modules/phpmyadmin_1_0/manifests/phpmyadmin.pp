class phpmyadmin_1_0::phpmyadmin (
$phpmyadmin_adm_ip = '',
$vhost
) {

  package {
    "phpmyadmin":
      ensure => present;
  }

  file {
    "/etc/apache2/sites-available/phpmyadmin":
      owner => root, group => root, mode => 644,
      content => template("phpmyadmin_1_0/phpmyadmin.erb"),
      require => Package["phpmyadmin"];
  }

  exec {
    "/bin/ln -s /etc/apache2/sites-available/phpmyadmin /etc/apache2/sites-enabled/phpmyadmin":
      require => File["/etc/apache2/sites-available/phpmyadmin"],
      unless => "test -f /etc/apache2/sites-enabled/phpmyadmin";
  }
}
