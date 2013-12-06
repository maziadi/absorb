class nfs_1_0::server ($exports){

  package {"nfs-kernel-server":
      ensure => present,
  }

  exec {"reload_nfs_srv":
      command => "/etc/init.d/nfs-kernel-server reload",
      refreshonly => true,
      require => Package["nfs-kernel-server"]
  }

  service {"nfs-kernel-server":
      enable => "true",
      pattern => "nfsd",
      require => Package["nfs-kernel-server"]
  }

  file {"/etc/exports":
      content => template("nfs_1_0/exports.erb"), 
      owner => root,
      group => root,
      mode => '0644',
      notify => Exec['reload_nfs_srv'],
      require => Package["nfs-kernel-server"]
  }

}
