class system_1_0::ssh_authorized_keys { 
  file { 
    "/root/.ssh": 
      owner => root, group => root, mode => 600,
      ensure => directory;
    "/root/.ssh/authorized_keys":
      owner => root, group => root, mode => 600,
      source => "${dist_files}/authorized_keys"
  }
}
