class vserver_1_0::base {
  set_etc_issue { issue: content => "vserver alphalink" }
}

class vserver_1_0::hvm inherits vserver_1_0::base {
}

class vserver_1_0::vserver inherits vserver_1_0::base {
  package {
    [
      "udev",
      "iozone3",
      "bonnie++"
    ]: ensure => present;
  }
  file {
    "/opt/local/bin/iozone.sh":
      source => "${files_root}/vserver_1_0/iozone.sh",
      mode => 700, owner => root, group => root;
  }
}
