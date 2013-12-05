class system_1_0::debian-development {
  include rubygems

  package {
    [ 
      "build-essential",
      "dpkg-dev",
      "devscripts",
      "dh-make",
      "debhelper",
      "dpatch",
      "flex",
      "bison",
      "xsltproc",
      "unison",
      "cvs",
      "libmysqlclient-dev",
      "libmysql-ruby1.8",
      "svn-buildpackage",
      "fakeroot",
      "pbuilder",
      "ri",
      "rails",
      "xulrunner-dev",
      "maven2",
      "gnupg-agent"
    ]: ensure => present; 
  }

  case $lsbdistcodename {
    "squeeze": {
      package {
        [
          "libsvn-java",
          "xulrunner-1.9.1",
        ] : ensure => present;
      }
    }
    default : {
      package {
        [
          "irb", 
          "libsvn-java",
          "xulrunner",
        ] : ensure => present;
      }
    }
  }

  case defined(Package["rake"])  {
    false: { package { "rake": ensure => present } }
  }
  case defined(Package["subversion"]) {
    false: { package { "subversion": ensure => present } }
  }

  # paquetages pour la compilation de openser
#  package {
#    [
#      "libmysqlclient15-dev",
#      "libexpat1-dev",
#      "libxml2-dev",
#      "libpq-dev",
#      "libradiusclient-ng-dev",
#      "zlib1g-dev",
#      "unixodbc-dev",
#      "libxmlrpc-c3-dev",
#      "libperl-dev",
#      "libsnmp-dev",
#      "libdb-dev",
#      "libconfuse-dev",
#      "libldap2-dev",
#      "tcl8.4-dev",
#      "java-gcj-compat-dev"
#    ] : ensure => present;
#  }
  # paquetages pour la compilation de openser
  package {
    [
      "libclamav-dev",
      "libpcre3-dev"
    ] : ensure => present;
  }
#  gem { ["rails", "mongrel", "capistrano", "mongrel_cluster", "mysql"]: require => Package ["libmysqlclient-dev"]}
}

class system_1_0::centrex-development {
  package { 
    [
      "sun-java5-jdk"
    ]: ensure => present;
  } 
}