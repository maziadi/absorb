#modules ocfs2_1_0
class ocfs2_1_0::base {
  case $ocfs2_1_0_primary_hostname        {'': { $ocfs2_1_0_primary_hostname        = '' } }
  case $ocfs2_1_0_secondary_hostname      {'': { $ocfs2_1_0_secondary_hostname      = '' } }
  case $ocfs2_1_0_primary_address         {'': { $ocfs2_1_0_primary_address         = '' } }
  case $ocfs2_1_0_secondary_address       {'': { $ocfs2_1_0_secondary_address       = '' } }

  package {
    [
      "ocfs2-tools",
      "ocfs2console",           
    ]: ensure => present;
  }

  replace {
    "activation de ocfs2 au boot":
      file        => "/etc/default/o2cb",
      pattern     => "^O2CB_ENABLED=false",
      replacement => "O2CB_ENABLED=true",
      require     => Package["ocfs2-tools"];
  }

  config_file {
    "/etc/ocfs2/cluster.conf":
      content => template("ocfs2_1_0/cluster.conf.erb"),
      require => Package["ocfs2-tools"];
  }

#  exec {
#  }

  file {
    "/data/images":
      ensure => directory;
  }
}
