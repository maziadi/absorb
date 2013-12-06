class erp_1_0::anderson(
$environment,
){

erp_1_0::rails_app {
  "anderson":
     uid=> "1012",
     gid=> "1012",
     environment=>$environment,
     ruby_version=> "jruby-1.6.7",
     unicorn_start=> false;
}
if ! Package["libmysqlclient-dev"] {
  package {
    [
      "libmysqlclient-dev",
    ]: ensure => present;
  }
}
package {
  [
    "zip",
    "subversion",
  ]: ensure => present;
}

monit_1_0::monit::monit_file {
  "anderson":
     requires => Package["anderson"]
}

file {
  "/etc/anderson/application.yml":
    owner => root, group => root, mode => 644,
    source => "${dist_files}/nodes/${hostname}/etc/anderson/application.yml",
    require => User["anderson"];
  "/data/anderson":
    owner => anderson, group => anderson, mode => 750,
    require => User["anderson"],
    ensure => directory;
  "/data/anderson/backup":
    owner => anderson, group => anderson, mode => 750,
    require => [User["anderson"],File["/data/anderson"]],
    ensure => directory;
  "/etc/anderson/database.yml":
    owner => root, group => root, mode => 644,
    content => template("erp_1_0/anderson/database.yml.erb"),
    require => User["anderson"];
  "/etc/anderson/neo4j-database.yml":
    owner => root, group => root, mode => 644,
    content => template("erp_1_0/anderson/neo4j-database.yml.erb"),
    require => User["anderson"];
}
include system_1_0::sun-jdk6
}
