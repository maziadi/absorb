#modules smart_1_0
class smart_1_0::tools {
  $smart_mail_admin = "smart@$email_domain_name"
  case $smart_start { '': { $smart_start = true } }
  case $smart_cciss { '': { $smart_cciss = false } }
  package {
    "smartmontools":
      ensure => present,
      before => File["/etc/default/smartmontools"];
  }
  
  file {
    "/etc/smartd.conf":
      content => template("smart_1_0/smartd.conf.erb"),
      notify  => Service["smartmontools"];
    "/etc/default/smartmontools":
      content => template("smart_1_0/smartmontools.erb"),
      before  => File["/etc/smartd.conf"];
  }
  
  if $smart_start {
    service {
      "smartmontools":
      ensure => running,
      pattern => "smartd";
    }
  }
  else {
    service {
      "smartmontools":
      ensure => stopped,
      pattern => "smartd";
    }
  }
}
