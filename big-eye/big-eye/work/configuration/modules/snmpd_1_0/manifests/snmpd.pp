class snmpd_1_0::snmpd-base {
    case $snmp_callweaver { '': { $snmp_callweaver = false } }
    case $snmp_asterisk { '': { $snmp_asterisk = false } }
    case $snmp_quality_interfaces { '': { $snmp_quality_interfaces = false } }
    case $snmp_maquette { '': { $snmp_maquette = false } }
    case $snmp_voip_maquette { '': { $snmp_voip_maquette = false } }
    case $snmp_apn { '': { $snmp_apn = false } }
    case $snmp_v3 { '' : { $snmp_v3 = false } }
    case $snmp_proxy { '' : { $snmp_proxy = false } }
    case $snmp_masterX { '' : { $snmp_masterX = false } }
    case $snmp_mibs_dir { '' : { $snmp_mibs_dir = "/usr/share/snmp/mibs" } }
    case $snmp_jace { '': { $snmp_jace = false } }
    case $snmp_portzamparc { '': { $snmp_portzamparc = false } }
    case $snmpd_options { '': { $snmpd_options = "LS6d" } }

    $snmpv3_authpass="rUm8CRqDN3q4fBa"    #c'est une constante - on ne peux pas changer le authpass en le modifiant ici! 
    $snmpv3_privpass="mPJr0LxbwxlH27X"    #c'est une constante - on ne peux pas changer le privpass en le modifiant ici!
    $snmpv3_username="snmpuser"

    define cfg_file($notify = Service["snmpd"], $mode = 644) {
      file {
        "${name}":
          owner => root,
          group => root,
          mode => $mode,
          source => [
            "${dist_files}/nodes/${hostname}/${name}",
            "${files_root}/snmpd_1_0/${name}"
          ],
          notify => $notify,
          require => Package["snmpd"];
      }
    }

    package {
        "snmpd":
            ensure => present;
    }
    file { 
        "/etc/snmp/snmpd.conf":
            owner => root, group => root, mode => 644,
            content => template("snmpd_1_0/snmpd.conf.erb"),
            require => Package["snmpd"],
            notify => Service["snmpd"];
        "/etc/default/snmpd":
            owner => root, group => root, mode => 600,
            content => template("snmpd_1_0/snmpd.erb"),
            require => Package["snmpd"],
            notify => Service["snmpd"];
    }

    service { "snmpd":
        enable => true,
        ensure  => running,
        hasstatus => false,
        hasrestart => true,
        pattern => '/usr/sbin/snmpd';
#        require => [File["/etc/snmp/snmpd.conf"], File["/etc/default/snmpd"]],
#        subscribe => [File["/etc/snmp/snmpd.conf"], File["/etc/default/snmpd"]]
    }

    if $snmp_quality_interfaces {
      cfg_file {
        "/opt/local/bin/mib_ifinfo.rb":
          mode    => 755,
          notify  => [];
      }
    }

    case $snmp_v3 {
      true: {
        exec {
          "create user snmpv3":
           unless  => "grep -q -w snmpuser /usr/share/snmp/snmpd.conf",
#           unless  => "snmpwalk -On -v2c -c 78Ggruzg4p localhost usmUserTable |grep -w ${snmpv3_username}"
#           unless  => "snmpwalk -v3 -u snmpuser -On -l authPriv -a MD5 -A ${snmpv3_authpass} -x DES -X ${snmpv3_privpass} localhost usmUserTable |grep -w ${snmpv3_username}",
           command => "/etc/init.d/snmpd stop && net-snmp-config --create-snmpv3-user -ro -A MD5 -a ${snmpv3_authpass} -X DES -x ${snmpv3_privpass} ${snmpv3_username}",
           before  => Service["snmpd"],
           require => Package["snmpd"];
        }
      }
    }
}

class snmpd_1_0::snmpd inherits snmpd_1_0::snmpd-base {
  #snmpd_1_0::snmpd-base::cfg_file {
  #  "/usr/share/snmp/mibs/ADAPTEC-UNIVERSAL-STORAGE-MIB.txt":
  #    notify  => [];
  #  "/usr/share/snmp/mibs/FOUNDRY-FAST-IRON-GS-03100A-MIB.txt":
  #    notify  => [];
  #}
}

class snmpd_1_0::snmpd-squeeze {
  $snmp_mibs_dir = "/usr/share/mibs"
  include snmpd_1_0::snmpd-base
  file {
    "/etc/snmp/snmp.conf":
      source => "${files_root}/snmpd_1_0/etc/snmp/snmp.conf",
      require => Package["snmpd"],
      notify => Service["snmpd"];
   # "${snmp_mib_dir}/ADAPTEC-UNIVERSAL-STORAGE-MIB.txt":
   #   owner => root,
   #   group => root,
   #   source => "${files_root}/snmpd_1_0/usr/share/snmp/mibs/ADAPTEC-UNIVERSAL-STORAGE-MIB.txt",
   #   require => Package["snmp-mibs-downloader"];
   # "${snmp_mib_dir}/FOUNDRY-FAST-IRON-GS-03100A-MIB.txt":
   #   owner => root,
   #   group => root,
   #   source => "${files_root}/snmpd_1_0/usr/share/snmp/mibs/FOUNDRY-FAST-IRON-GS-03100A-MIB.txt",
   #   require => Package["snmp-mibs-downloader"];
  }
  
  package {
    "snmp-mibs-downloader":
      ensure => present;
  }
}

class snmpd_1_0::snmpd-wheezy inherits snmpd_1_0::snmpd-squeeze {
}
