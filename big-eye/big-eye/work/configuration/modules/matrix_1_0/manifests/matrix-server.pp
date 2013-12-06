class matrix_1_0::matrix-server {
  case $matrix_host { '': {$matrix_host = '$(uname -n)'} }
  
  include system_1_0::sun-jdk6

  package {
    "matrix-server": ensure => present;
  }
  config_file {
    "/etc/jetty/contexts/matrix.xml":
      content => template("matrix_1_0/matrix-server/matrix.xml.erb"),
      require => Package["matrix-server"];
    "/etc/jetty/web_matrix.xml":
      content => template("matrix_1_0/matrix-server/web_matrix.xml.erb"),
      require => Package["matrix-server"];
    "/etc/default/jetty":
      content => template("matrix_1_0/matrix-server/jetty.erb"),
      require => Package["matrix-server"];
  }
  file {
    "/var/lib/matrix/db":
      owner => jetty, group => jetty, mode => 775,
      ensure => directory,
      require => Package["matrix-server"];
    "/usr/share/java/webapps":
      owner => jetty, group => jetty, mode => 775,
      ensure => directory,
      require => Package["matrix-server"];
  }
}
