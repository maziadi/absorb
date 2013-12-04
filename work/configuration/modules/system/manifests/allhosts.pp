
class system::allhosts {
  $node_files = "${dist_files}/nodes/${hostname}"
  $autoupdate = $autoupdate ? { '' => false, default => true }
  $resolv_searches = $resolv_searches ? { '' => ["${domain_name}", 'alphalink.fr'], default => $resolv_searches }
  $resolv_nameservers = $resolv_nameservers ? { '' => ["${primary_dns}", "${secondary_dns}"], default => $resolv_nameservers }

  host { 
    "gold.alphalink.fr":
      alias => "gold",
      ensure => present,
      ip => "217.15.80.75"
  }

  file { 
    "/etc/sudoers":
      owner => root, group => root, mode => 440,
      content => template("system/sudoers/sudoers.erb");
    "/etc/sysctl.conf":
      owner => root, group => root, mode => 644; 
    "/etc/resolv.conf":
      owner => root, group => root, mode => 644, 
      content => template("system/resolv.conf.erb");
    "/etc/puppet/puppet.conf":
      owner => root, group => root, mode => 644, 
      content => template("system/puppet/puppet.conf.erb");
    "/etc/puppet/puppetd.conf":
      ensure => absent; 
  }
  file {
    [ 
      "/opt",
      "/opt/local",
      "/opt/local/bin",
      "/opt/local/etc",
      "/opt/local/share",
      "/data"
        ] : owner => root, group => root, mode => 755, ensure => directory;
  }
  package { 
    "sudo": 
      ensure => present, 
      before => File["/etc/sudoers"];
  }
  package {
    [
      "screen", 
      "less", 
      "rsync", 
      "bzip2", 
      "lsof", 
      "ifenslave"
    ]: ensure => present;
  }
  service { 
    "puppet":
      enable => $autoupdate, 
      ensure => $autoupdate,
      pattern => '/usr/sbin/puppetd -w 0', # necessaire pour ne pas matcher une execution manuelle
      subscribe => File["/etc/puppet/puppet.conf"];
    "cron":
      enable => true, ensure => running;
  }
  group { 
    $cdp_group: ensure => "present", gid => 2101;
    $devel_group: ensure => "present", gid => 2102;
  }
}
