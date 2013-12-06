class system::debian-desktop {
  include system::debian
  include system::ssh_authorized_keys
  include admin_users
  include system::sun-jdk
  include rubygems, openntpd

  $frontend = $frontend ? {'' => "gnome", default => $frontend}

  package {
  [
    "dialog",
    "gkrellm",
    "icedove",
    "icedove-l10n-fr",
    "iceweasel",
    "iceweasel-l10n-fr",
    "keepassx",
    "libcmdparse2-ruby",
    "libtmail-ruby1.8",
    "minicom",
    "openoffice.org",
    "pidgin",
    "rake",
    "rdesktop",
    "ruby",
    "smbfs",
    "subversion",
    "x-window-system",
    "xterm",
    "zenity",
  ]: ensure => present;
  }
  
  case $frontend {
  gnome: { package { [ "gnome", "gdm" ]: ensure => present } }
  kde: { package { 
    [
    "basket",
    "kdm", 
    "kdebase", 
    "kde-kdm-themes",
    "konqueror",
    "psi",
    "xtightvncviewer",
    ]: ensure => present } 
  }

  fluxbox: { package { [ "fluxbox", "gnome-terminal" ]: ensure => present } }
  }
}
