class ssh_1_0::sshd {
  case $ssh_listen_addr { '': { $ssh_listen_addr = false } } 
  case $enable_sftp { '': { $enable_sftp = false } }
  case $ssh_root_auth { '': { $ssh_root_auth = true } }
  case $ssh_password_auth {
    '': {
      if $enable_sftp {
        $ssh_password_auth = true
      }
      else {
        $ssh_password_auth = false
      }
    }
  }

  package {
    "ssh":
      ensure => present;
  }
  file {
    "/etc/ssh/sshd_config":
        owner => root, group => root, mode => 644,
        content => template("ssh_1_0/sshd_config.erb"),
        require => Package["ssh"],
        notify => Service["ssh"];
  }
  service { "ssh":
        enable  => true,
        ensure  => running,
        hasrestart => true,
        pattern => '/usr/sbin/sshd';
  }
  if $enable_sftp {
    file {
      "/data/sftp":
        owner => root, group => root, mode => 750,
        ensure => directory;
    }
  }
}
