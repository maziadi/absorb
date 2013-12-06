class system::debian {
  define add_apt_gpg_key($filename, $keyid) {
    file { "${gpg_repo}/${filename}":
      ensure => present,
      owner => root, group => root, mode => 444,
      source => "${files_root}/system/debian/${gpg_repo}/${filename}",
      require => File["$gpg_repo"]
    }
    exec { "Adding key ${filename} with id ${keyid}":
      unless  => "apt-key list | grep -q '${keyid}'",
      command => "apt-key add '${gpg_repo}/${filename}'",
      require => File["${gpg_repo}/${filename}"],
      notify  => Exec["apt-cache-refresh"];
    }
  }

  include system::allhosts
  $gpg_repo = "/opt/local/etc/apt-gpg-keys"

  file { "$gpg_repo":
    owner => root, group => root, mode => 755,
    ensure => directory;
  }
  add_apt_gpg_key { "alphalink key": filename => "ALPHALINK-GPG-KEY", keyid => "9AF0E473"}

  case $volatile_repository { '': { $volatile_repository = false } }
  case $volatile_lenny_repository { '': { $volatile_lenny_repository = false } }
  case $sarge_repository { '': { $sarge_repository = false } }
  case $etch_repository { '': { $etch_repository = true } }
  case $lenny_repository { '': { $lenny_repository = false } }
  case $squeeze_repository { '': { $squeeze_repository = false } }
  case $sid_repository { '': { $sid_repository = false } }
  case $dev_source_repository { '': { $dev_source_repository = false }}
  case $voip_repository { '': { $voip_repository = false }}
  case $opennms_repository { '': { $opennms_repository = false } }
  case $webmin_repository { '': { $webmin_repository = false } }
  case $intellique_repository { '' : { $intellique_repository = false } }

  $debian_extra_kopt = $debian_console ? { 
  	default => "console=tty console=ttyS0,19200n8", 
	  false => 'console=tty' 
  }

  if $opennms_repository {
    add_apt_gpg_key { "opennms key": filename => "OPENNMS-GPG-KEY", keyid => "4C4CBBD9" } 
    file {
    "/etc/apt/preferences":
      content => template("system/apt/preferences.erb");
    }
  }
  # Pour les SAN
  case $bootloader_lilo { '': { $bootloader_lilo = false } }

  file {
    "/etc/kernel-img.conf":
      owner => root, group => root, mode => 644,
      content => template('system/debian/kernel-img.conf.erb');
    "/etc/profile":
      owner => root, group => root, mode => 645,
      source => "${files_root}/system/debian/etc/profile";
    "/etc/profile.alphalink.sh":
      owner => root, group => root, mode => 644,
      source => "${files_root}/system/profile.alphalink.sh";
    "/etc/timezone":
      content => "Europe/Paris\n";
    "/etc/localtime":
      source => "/usr/share/zoneinfo/Europe/Paris";
    "/etc/apt/sources.list":
      content => template("system/apt/sources.list.erb");
    "/root/.screenrc":
      owner => root, group => root, mode => 644,
      source => "${files_root}/system/screenrc";
    "/root/.vimrc":
      owner => root, group => root, mode => 644,
      source => "${files_root}/system/vimrc";
    "/root/.vim":
      owner => root, group => root, recurse => true,
      source => "${files_root}/system/vim";
    "/opt/local/bin/check-eth-status":
      owner => root, group => root, mode => 755,
      source => "${files_root}/system/debian/opt/local/bin/check-eth-status",
      require => [Package["ethtool"],Package["iproute"],File["/opt/local/bin"]];
  }
  exec {
    apt-cache-refresh:
      command => "apt-get update",
      require => File["/etc/apt/sources.list"],
      #refreshonly => true,
      #subscribe => File["/etc/apt/sources.list"];
  }
  replace { suppress_root_PS1_config:
    file => "/root/.bashrc",
    pattern => ".*export PS1=.*",
    replacement => "# \\0"
  } 	
  package {
    # TODO: use purged when supported
    "ca-certificates": ensure => latest;
    "debian-archive-keyring": ensure => latest;
    "iproute": ensure => present;
    "bridge-utils": ensure => present;
    "avahi-daemon": ensure => absent;
    "nfs-common": ensure => absent;
    "openbsd-inetd": # il en faut un, on le desactive plus loin
      ensure => present,
      before => Service["openbsd-inetd"];
    "portmap": ensure => absent;
    "procps": ensure => present;
    "tasksel": ensure => absent;
    "xfsprogs": ensure => present;
  }
  package {
    [
      "apt-show-versions",
      "bond",
      "eparpmon",
      "ethtool",
      "host",
      "iftop",
      "ipcalc",
      "mtr",
      "ngrep",
      "nmap",
      "ssh",
      "sysstat",
      "tcpdump",
      "telnet",
      "vim",
      "vlan",
    ]: ensure => present;
  }
  service { "openbsd-inetd":
    ensure => stopped,
    enable => false,
  }
  user { "asupprimer": ensure => absent } 
  file { "/home/asupprimer": ensure => absent, force => true }

  define debconf_set_selections($package) {
    exec {
      "debconf-set-selections of '${name}'":
        command => "echo '${debconf_set_selections}' | debconf-set-selections",
        unless => "dpkg -l '${package}' | grep -q '^ii.*${package}'",
        before => Package["${package}"];
    }
  
  }

  exec {
    "update_grub":
      command => "/usr/sbin/update-grub",
      refreshonly => true;
  }

  replace {
    "adding ${debian_extra_kopt} to kopt menu.lst":
      file => "/boot/grub/menu.lst",
      pattern => '^(# kopt=root=/dev/.* ro).* $',
      replacement => "\\1 ${debian_extra_kopt}",
      notify => Exec['update_grub'];
  }
  include atop 
}
