class system::gentoo {
  include system::allhosts
  
  cron { eix-sync:
    command => "/usr/bin/eix-sync",
    user => root,
    hour => 5,
    minute => 13 
  }
  file { 
    "/etc/profile.d":
      owner => root, group => root, mode => 755,
      ensure => directory;
    "/etc/profile.d/profile.alphalink.sh":
      owner => root, group => root, mode => 755,
      source => "${files_root}/system/profile.alphalink.sh"
  }
  package {
    [
      "iproute2",
      "vconfig"
    ] : ensure => present;
  }
}
