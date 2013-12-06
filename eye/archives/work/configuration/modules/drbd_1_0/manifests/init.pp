#modules drbd_1_0
class drbd_1_0::drbd_1_0_base {
  
  case $drbd_1_0_primary_hostname   {'': { $drbd_1_0_primary_hostname    = '' } }
  case $drbd_1_0_primary_address    {'': { $drbd_1_0_primary_address     = '' } }
  case $drbd_1_0_secondary_hostname {'': { $drbd_1_0_secondary_hostname  = '' } }
  case $drbd_1_0_secondary_address  {'': { $drbd_1_0_secondary_address   = '' } }
  case $architecture {
    amd64:  {
      package {
         [
           "drbd8-2.6.32-bpo.3-amd64",
           "drbd8-utils",
         ]:
           ensure => latest;
       }
    }
   # i386:{
   #   package {
   #      [
   #        "drbd8-modules-2.6.26-",
   #        "drbd8-utils",
   #      ]:
   #        ensure => present;
   #    }
   # }
  }
}

class drbd_1_0::drbd_1_0_on_device inherits drbd_1_0::drbd_1_0_base {

  #case $drbd_1_0_resource    {'': { $drbd_1_0_resource    = '' } }
  #case $drbd_1_0_disk        {'': { $drbd_1_0_disk        = '' } }
  #case $drbd_1_0_device      {'': { $drbd_1_0_device      = '' } }
  #case $drbd_1_0_port        {'': { $drbd_1_0_port        = '' } }

  #replace { "set_lvm.conf modifications" :
  #  file => "/etc/lvm/lvm.conf",
  #  pattern => '    filter = [ "a/.*/" ]',
  #  replacement => '    filter = [ "r|/dev/sda3|", "a|/dev/drbd0|" ]';
  #}

  host_file {
    "/etc/drbd.conf":
      require => Package["drbd8-utils"],
  }
}


class drbd_1_0::drbd_1_0_on_lv inherits drbd_1_0::drbd_1_0_base {
}

class drbd_1_0::drbd_pacemaker (
  $allow_dual_primary = false
) {
  package {
    "drbd8-utils":
      ensure => present;
  }
  service {
    "drbd":
      enable => false;
  }
  file {
    "/etc/drbd.conf":
      mode => 600, owner => root, group => root,
      source => "${files_root}/drbd_1_0/drbd.conf",
      require => Package["drbd8-utils"];
    "/etc/drbd.d/global_common.conf":
      mode => 600, owner => root, group => root,
      content => template("drbd_1_0/global_common.conf.erb"),
      require => Package["drbd8-utils"];
  }
}

class drbd_1_0::load_module {
    exec { "load drbd module":
              command => "modprobe drbd",
              creates => "/proc/drbd";
    }
}

define drbd_1_0::config ($content) {
  file { "/etc/drbd.d/${name}.res":
      mode => "0600",
      owner => "root",
      content => "# file managed by puppet\n\n${content}\n",
  }
}

define drbd_1_0::resource ($host1, $host2, $ip1, $ip2, $port='7789', $vg='data',$size = '0',$device='/dev/drbd0') {

  drbd_1_0::config { "${name}":
    content => template("drbd_1_0/drbd.res.erb"),
  }

#  if $manage {

    # create metadata on device, except if resource seems already initalized.
    exec { "create LVM volume $name":
              command => "lvcreate -L $size -n /dev/${vg}/${name}",
              creates => "/dev/${vg}/${name}",
    }
    exec { "intialize DRBD metadata for $name":
              command => "drbdadm create-md $name",
              onlyif => "test -e /dev/${vg}/${$name}",
              unless => "drbdadm dump-md $name || (drbdadm cstate $name | egrep -q '^(Sync|Connected)')",
              require => [
                Exec["load drbd module"],
                Exec["create LVM volume $name"],
                Drbd_1_0::Config["${name}"],
              ],
    }

    exec { "enable DRBD resource $name":
              command => "drbdadm up $name",
              unless => "drbdadm role $name | egrep -q '^Secondary|^Primary' ",
              require => [
                Exec["intialize DRBD metadata for $name"],
                Exec["load drbd module"],
              ],
    }
  #}
}

