class repository_0_0::aptcacher {
  case $aptcacher_create_lv { '': { $aptcacher_create_lv = false } } 
  package {
    "apt-cacher-ng":
      ensure => present,
      before => File["/etc/apt-cacher-ng/acng.conf"];
  }

  file {
   "/etc/apt-cacher-ng/acng.conf":
      content => template("repository_0_0/aptcacher/acng.conf.erb"),
      before  => Service["apt-cacher-ng"],
      notify  => Service["apt-cacher-ng"];
  }

  service {
    "apt-cacher-ng":
      ensure => running;
  }  
  case $aptcacher_create_lv {
    true : {
      file {
        "/opt/local/bin/create-aptcacher-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/repository_0_0/aptcacher/create-aptcacher-lv";
      }

      exec { "Create aptcacher LV":
        require => File["/opt/local/bin/create-aptcacher-lv"],
        unless => "lvdisplay /dev/data/apt-cacher-ng",
        command => "/opt/local/bin/create-aptcacher-lv",
        before => Package["apt-cacher-ng"]
      }
    } 
  }
}
