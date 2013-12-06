class repository_0_0::debian-client {
  package {
    "dput": ensure => present;
  }
  file {
    "/etc/dput.cf":
      owner => root, group => root, mode => 644,
      content => template("repository_0_0/debian-client/dput.cf.erb");
    "/opt/local/bin/publish_reprepro.sh":
      owner => root, group => root, mode => 755,
      source => "${files_root}/repository_0_0/debian-client/opt/local/bin/publish_reprepro.sh",
      require => File["/opt/local/bin"];
    "/opt/local/bin/put_gems":
      owner => root, group => root, mode => 755,
      source => "${files_root}/repository_0_0/debian-client/opt/local/bin/put_gems",
      require => File["/opt/local/bin"];
  }
}
