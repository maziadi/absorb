class erp::clockwork {

  package {
    "clockwork":
      require => [File["/srv/clockwork"]],
      ensure => present;
  }

  group {
    "clockwork":
      ensure  => present,
      gid     => "1008"
  }

  user {
    "clockwork":
      ensure  => present,
      uid     => "1008",
      gid     => "1008",
      comment => "Clockwork User",
      home    => "/srv/clockwork",
      shell   => "/bin/bash",
      require => Group["clockwork"]
  }
  file {
    "/srv/clockwork":
      owner => clockwork, group => clockwork, mode => 750,
      require => [User["clockwork"],Group["clockwork"]],
      ensure => directory;
  }

  exec {
    "reload_gpg":
      command => "gpg --import /srv/clockwork/config/alpha.gpg || true",
      cwd => "/srv/clockwork",
      user => "clockwork",
      refreshonly => true,
      require => [Package["gnupg"],File["/srv/clockwork/config/alpha.gpg"]];
  }
  package {
      "gnupg": ensure => present;
  }
  file {
    "/srv/clockwork/.gnupg":
      owner => clockwork, group => clockwork, mode => 700,
      ensure => directory,
      require => [Package["gnupg"],File["/srv/clockwork"]];
    "/srv/clockwork/config/alpha.gpg":
      owner => clockwork, group => clockwork, mode => 600,
      source => "${files_root}/erp/alpha.gpg",
      require => [Package["clockwork"],File["/srv/clockwork/.gnupg"]];
    "/etc/logrotate.d/clockwork":
      owner => root, group => root, mode => 644,
      source => "${files_root}/erp/logrotate_clockwork",
      require => [Package["clockwork"]];
  }
}
