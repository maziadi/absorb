class system_1_0::debian {
  define add_apt_gpg_key($filename) {
    $gpg_repo = "/opt/local/etc/apt-gpg-keys"
    file { "${gpg_repo}/${filename}":
      ensure => present,
      owner => root, group => root, mode => 444,
      source => "${files_root}/system_1_0/debian/${gpg_repo}/${filename}",
      notify => Exec["refresh_apt_gpg_keys-${filename}"]
    }
    exec { "refresh_apt_gpg_keys-${filename}":
      command => "apt-key add '${gpg_repo}/${filename}'",
      require => File["${gpg_repo}/${filename}"],
      refreshonly => true,
      notify  => Exec["apt-cache-refresh"];
    }
  }

  include system_1_0::allhosts
  case $apt_preferences { '': { $apt_preferences = false } }
  case $zimbra_1_0_preferences { '': { $zimbra_1_0_preferences = false } }
  # c'est deux variables sont nécéssaires pour les pb de caches
  # a refactorer au besoin
  case $apt_conf        { '': { $apt_conf = false } }
  case $apt_cache_limit { '': { $apt_cache_limit = false } }
  case $inetd        { '': { $inetd = true } }
  case $repositories {
    '': {
        fail("repositories must be fill in by the repository wanted\n")
    }
  }
 
  case $activate_proxy_apt {
    false: {
      # si $proxy_apt = "", aucun proxy utilise
      case $proxy_apt       { '': { $proxy_apt = "" } }
    }    
    '': {
      case $proxy_apt       { '': { $proxy_apt = "gold.alphalink.fr:3142/" } }
    }
  }
  case $varlog_create_lv { '': { $varlog_create_lv = false } }
  case $varlog_vg_name { '': { $varlog_vg_name = "data" } }
  case $varlog_lv_size { '': { $varlog_lv_size = "10G" } }

 file { 
   "/opt/local/etc/apt-gpg-keys":
     owner => root, group => root, mode => 755,
     ensure => directory;
  }

  add_apt_gpg_key { "alphalink key": filename => "ALPHALINK-GPG-KEY"}

  $debian_extra_kopt = $debian_console ? { 
  	default => "console=tty console=ttyS0,19200n8", 
	  false => 'console=tty' 
  }

  # Pour les SAN
  case $bootloader_lilo { '': { $bootloader_lilo = false } }

  file {
    "/etc/kernel-img.conf":
      owner => root, group => root, mode => 644,
      content => template('system_1_0/debian/kernel-img.conf.erb');
    "/etc/profile":
      owner => root, group => root, mode => 645,
      source => "${files_root}/system_1_0/debian/etc/profile";
    "/etc/profile.alphalink.sh":
      owner => root, group => root, mode => 644,
      source => "${files_root}/system_1_0/profile.alphalink.sh";
    "/etc/timezone":
      content => "Europe/Paris\n",
      require => Package["tzdata"];
    "/etc/locale.gen":
      content => "en_US.UTF-8 UTF-8\nfr_FR.UTF-8 UTF-8\n",
      require => Package["locales"];
    "/etc/apt/sources.list":
      content => template("system_1_0/apt/sources.list.erb");
    "/root/.screenrc":
      owner => root, group => root, mode => 644,
      source => "${files_root}/system_1_0/screenrc";
    "/root/.vimrc":
      owner => root, group => root, mode => 644,
      source => "${files_root}/system_1_0/vimrc";
    "/root/.vim":
      owner => root, group => root, recurse => true,
      source => "${files_root}/system_1_0/vim";
    "/opt/local/bin/check-eth-status":
      owner => root, group => root, mode => 755,
      source => "${files_root}/system_1_0/debian/opt/local/bin/check-eth-status",
      require => [Package["ethtool"],Package["iproute"],File["/opt/local/bin"]];
  }

  if $apt_preferences {
    file {
    "/etc/apt/preferences":
      content => template("system_1_0/apt/preferences.erb");
    }
  }
  
  if $apt_conf {
    file {
    "/etc/apt/apt.conf":
      content => template("system_1_0/apt/apt.conf.erb");
    }
  }
  
  exec {
    "apt-cache-refresh":
      command => "aptitude update",
      require => File["/etc/apt/sources.list"];
    "locale-gen":
      subscribe   => File["/etc/locale.gen"],
      refreshonly => true,
      require     => Package["locales"];
    "update-locale LANG=en_US.utf8":
      require  => Package["locales"],
      unless => "grep -q ^LANG=en_US.utf8$ /etc/default/locale",
      command => "update-locale LANG=en_US.utf8";
  }

  replace { suppress_root_PS1_config:
    file => "/root/.bashrc",
    pattern => ".*export PS1=.*",
    replacement => "# \\0"
  } 	
  package {
    # TODO: use purged when supported
    "initsys-tools": ensure => present;
    "bridge-utils": ensure => present;
    "ca-certificates": ensure => latest;
    "debian-archive-keyring": ensure => latest;
    "iproute": ensure => present;
    "procps": ensure => present;
    "tasksel": ensure => absent;
    "xfsprogs": ensure => present;
  }
  if $inetd {
      service { "openbsd-inetd":
        ensure => stopped,
        enable => false,
      }
      package {
        "openbsd-inetd": # il en faut un, on le desactiven
          ensure => present,
          before => Service["openbsd-inetd"];
      }
  }
  case $lsbdistcodename {
    "wheezy": {
      package {
        "bond": ensure => purged;
      }
      exec {
        "change ruby alternative":
          command => "update-alternatives --set ruby /usr/bin/ruby1.8",
          unless => "update-alternatives --query ruby  | grep Value | grep ruby1.8";
      }
      file {
        "/etc/localtime":
          source  => "/usr/share/zoneinfo/posix/Europe/Paris",
          require => Package["tzdata"];
      }
    }
    "squeeze": {
      package {
       "eparpmon" : ensure => present;
      }
      package {
        "bond": ensure => purged;
      }
      file {
        "/etc/apt/preferences.d/puppet":
          owner => root, group => root, mode => 644,
          ensure => absent,
          source => "${files_root}/system_1_0/debian/etc/apt/preferences.d/puppet";
        "/etc/default/puppet":
          owner => root, group => root, mode => 644,
          source => "${files_root}/system_1_0/debian/etc/default/puppet";
        "/etc/localtime":
          source  => "/usr/share/zoneinfo/Europe/Paris",
          require => Package["tzdata"];
      }
    }
    default: {
      package {
       [ "bond", "eparpmon" ]: ensure => present;
      }
      file {
        "/etc/localtime":
          source  => "/usr/share/zoneinfo/Europe/Paris",
          require => Package["tzdata"];
      }
    }
  }
  package {
    [
#      "apt-show-versions",
      "ethtool",
      "host",
      "iftop",
      "ipcalc",
      "locales",
      "mtr",
      "ngrep",
      "nmap",
      "sysstat",
      "tcpdump",
      "telnet",
      "tzdata",
      "vim",
      "vlan",
      "acpid",
    ]: ensure => present;
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

  # Pour marquer un paquet
  define dpkg_set_selection($package) {
    exec {
      "dpkg --set-selections of '${name}'":
        command => "echo '${package} hold' | dpkg --set-selections",
        require => Package["${package}"];
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

  case $varlog_create_lv {
    true : {
      file {
        "/opt/local/bin/create-varlog-lv":
          owner => root, group => root, mode => 700,
          ensure => present,
          content => template("system_1_0/create-varlog-lv.erb");
      }

      exec { "Create var_log LV":
        require => File["/opt/local/bin/create-varlog-lv"],
        unless => "lvdisplay /dev/mapper/${varlog_vg_name}-var_log",
        command => "/opt/local/bin/create-varlog-lv";
      }
    }
  }
}
