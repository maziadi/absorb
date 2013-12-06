class system_1_0::debian-desktop {
  case $ssh_password_auth { '': { $ssh_password_auth = true } }
  include system_1_0::debian
  include system_1_0::ssh_authorized_keys
  include admin_users
  include system_1_0::sun-jdk6
  include rubygems, ntp_2_0::client
  include ssh_1_0::sshd
  #case $frontend { '': { $frontend = "gnome" } }

  package {
    [
      "alsa-utils",
      "dialog",
      "ed",
      "gkrellm",
      "icedove",
      "icedove-l10n-fr",
      "iceweasel",
      "iceweasel-l10n-fr",
      "keepassx",
      "libcmdparse2-ruby",
      "libopen4-ruby1.8",
      "libtmail-ruby1.8",
      "minicom",
      "openoffice.org",
      "pidgin",
      "rake",
      "rdesktop",
      "ruby",
      "smbfs",
      "subversion",
      "wireshark",
      "xterm",
      "xdm",
      "zenity",
      "yago-client",
      "git",
      "meld",
      "gitk",
      "tig",
      # libs for yago
      "libgtk2.0-0",
      "libexpat1",
      "libselinux1",
      "libpcre3",
    ]: ensure => present;
  }
  case $architecture {
    "x86_64": {
      package {
        [
          "ia32-libs-gtk",
        ] : ensure => present;
      }
    }
  }
  case $lsbdistcodename {
    "wheezy": {
      package {
        [
          "xorg",
        ] : ensure => present;
      }
    }
    "squeeze": {
      package {
        [
          "xorg",
        ] : ensure => present;
      }
    }
    default : {
      package {
        [
          "x-window-system",
          "more",
        ] : ensure => present;
      }
    }
  }
  case $frontend {
    kde: { package { 
      [
      "basket",
      "kdm", 
      "kdebase", 
      "konqueror",
      "psi",
      "xtightvncviewer",
      ]: ensure => present } 
    }
    fluxbox: { package { 
      [ 
        "evince", 
        "fluxbox", 
        "gnome-terminal", 
        "rox-filer",
        "xfe",
      ]: ensure => present } }
    gnome: { 
      package { 
        "gnome": ensure => present;
      } 
    }
  }
  package{"nfs-common": ensure => absent;}
}
