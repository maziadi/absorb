class fdroid_1_0::fdroid (
$keystorepass="",
$keypass=""
) {

  package {
    "git":
      ensure => present;
    "unzip":
      ensure => present;
    "sun-java6-jdk":
      ensure => present;
    "sun-java6-jre":
      ensure => present;
  }

#
# nginx
#
  package {
    "nginx":
      ensure => present;
  }

  file {
    "/etc/nginx/sites-available/default":
      owner => root, group => root, mode => 644,
      content => template("fdroid_1_0/nginx/default.erb"),
      require => Package["nginx"];
  }

#
# fdroid
#
  file {
    "/opt/local/bin/install.sh":
      owner => root, group => root, mode => 750,
      content => template("fdroid_1_0/fdroid/scripts/install.sh.erb"),
      require => [Package["git"],Package["unzip"]];
  }

  exec {
    "install":
      command => "/opt/local/bin/install.sh",
      require => File["/opt/local/bin/install.sh"],
      user => root;
  }

  package {
   "ia32-libs":
      ensure => present,
      require => Exec["install"];
  }

  file {
    "/var/lib/fdroiddata/config.py":
      owner => root, group => root, mode => 644,
      content => template("fdroid_1_0/fdroid/config.py.erb"),
      require => Exec["install"];
    "/var/lib/fdroiddata/repo.keystore":
      owner => root, group => root, mode => 644,
      source => "${files_root}/fdroid_1_0/repo.keystore",
      require => Exec["install"];
  }

}
