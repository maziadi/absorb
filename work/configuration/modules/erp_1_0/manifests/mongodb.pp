class erp_1_0::mongodb-base {
  case $mongodb_create_lv { '': { $mongodb_create_lv = false } }
  case $mongodb_vg_name { '': { $mongodb_vg_name = "data" } }
  case $mongo_replica_set { '': { $mongo_replica_set = false } }
  package {
    [
      "mongodb",
      "mongodb-clients",
    ]: ensure => present;
  }

  case $mongodb_create_lv {
    true : {
      file {
        "/opt/local/bin/create-mongodb-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          source => "${files_root}/erp_1_0/mongodb/create-mongodb-lv";
      }

      exec { "Create Mongodb LV":
        require => File["/opt/local/bin/create-mongodb-lv"],
        unless => "lvdisplay /dev/${mongodb_vg_name}/mongodb",
        command => "/opt/local/bin/create-mongodb-lv",
        before => Package["mongodb"]
      }
    }
  }
  file {
    "/etc/mongodb.conf":
      owner => root, group => root, mode => 644,
      content => template('erp_1_0/mongodb/mongodb.conf.erb'),
      require => Package["mongodb"];
    "/etc/logrotate.d/mongodb":
      owner => root, group => root, mode => 644,
      source => "${files_root}/erp_1_0/mongodb/logrotate",
      require => Package["mongodb"];
  }
  monit_1_0::monit::monit_file {
    "mongodb":
       requires => Package["mongodb"];
  }
}
