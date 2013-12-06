class repository_0_0::reprepro {
  include repository_0_0::apache 
  package {
      "reprepro": ensure => present;
      "gnupg": ensure => present;
  }
  file {
    "/root/.gnupg":
      owner => root, group => root, mode => 700,
      ensure => directory;
    "${packages_dir}/debian":
      owner => root, group => root, mode => 755,
      ensure => directory,
      require => File["${packages_dir}"];
    "${packages_dir}/debian/conf":
      owner => root, group => root, mode => 750,
      ensure => directory,
      require => File["${packages_dir}/debian"];
    "${packages_dir}/debian/db":
      owner => root, group => root, mode => 750,
      ensure => directory,
      require => File["${packages_dir}/debian"];
    "${packages_dir}/debian/incoming":
      owner => root, group => root, mode => 750,
      ensure => directory,
      require => File["${packages_dir}/debian"];
    "${packages_dir}/debian/conf/uploaders":
      owner => root, group => root, mode => 640,
      source => "${files_root}/repository_0_0/reprepro/${packages_dir}/debian/conf/uploaders",
      require => File["${packages_dir}/debian"];
    "${packages_dir}/debian/ALPHALINK.GPG":
      owner => root, group => root, mode => 755,
      source => "${files_root}/repository_0_0/reprepro/${packages_dir}/debian/ALPHALINK.GPG",
      require => File["${packages_dir}/debian"];
    "${packages_dir}/debian/conf/gpg_uploaders":
      owner => root, group => root, mode => 640,
      source => "${files_root}/repository_0_0/reprepro/${packages_dir}/debian/conf/gpg_uploaders",
      require => File["${packages_dir}/debian"],
      notify => Exec["reload_gpg_uploaders"];
    "/opt/local/bin/publish_lisos_prod":
      owner => root, group => root, mode => 750,
      source => "${files_root}/repository_0_0/reprepro/publish_lisos_prod";
  }
  exec {
    "reload_gpg_uploaders":
      command => "gpg --import ${packages_dir}/debian/conf/gpg_uploaders || true",
      refreshonly => true,
      require => [ Package["gnupg"],File["${packages_dir}/debian/conf/gpg_uploaders"]];
  }

  define create_incoming_dirs(){
    file {
      "${packages_dir}/debian/incoming/${name}":
        owner => root, group => root, mode => 750,
        ensure => directory,
        require => File["${packages_dir}/debian/incoming"];
    }
  }
  create_incoming_dirs {$repository_debian: }

  config_file {
    "${packages_dir}/debian/conf/distributions":
      content => template("repository_0_0/reprepro/distributions.erb"),
      require => [Package["reprepro"],File["${packages_dir}/debian/conf"]];
    "${packages_dir}/debian/conf/incoming":
      content => template("repository_0_0/reprepro/incoming.erb"),
      require => [Package["reprepro"],File["${packages_dir}/debian/conf"]];
  }
}
