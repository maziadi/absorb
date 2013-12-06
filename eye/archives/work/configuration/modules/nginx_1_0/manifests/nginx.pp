class nginx_1_0::nginx (
  $default_www_directory = "/var/www/nginx-default",
  $port = '80',
  $servername = 'localhost'
) {

  package {
    "nginx": 
      ensure => present;
  }
  # Les fichiers de conf etch et lenny ne semblent pas compatibles, ajout de rep de conf pour la version lenny

  config_file {
    "/etc/nginx/nginx.conf" :
      notify => Service["nginx"],
      content => template('nginx_1_0/nginx.conf.erb'),
      require => Package["nginx"],
      before => Service["nginx"];
  }

  file {
    "/etc/nginx/sites-enabled/default":
      ensure => absent;
  }

  service { 
    "nginx":
      enable  => true,
      ensure  => running;
  }
}
