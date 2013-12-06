class system_1_0::unattended-upgrades (
$env,
$origin_security = true,
$origin_stable = false,
$origin_updates = false,
$origin_proposed_updates = false,
$autoremove = false,
$reboot = false,
$enable = 1
) {

  $mail = $env ? { "production" => "noc-alerts@alphalink.fr", default => "dev-noc-alerts@alphalink.fr" }

  package {
    "unattended-upgrades":
      ensure => present;
  }

  file {
    "/etc/apt/apt.conf.d/50unattended-upgrades":
      owner => root, group => root, mode => 644,
      content => template("system_1_0/unattended-upgrades/unattended-upgrades.erb"),
      require => Package["unattended-upgrades"];
    "/etc/apt/apt.conf.d/02periodic":
      owner => root, group => root, mode => 644,
      content => template("system_1_0/unattended-upgrades/periodic.erb"),
      require => Package["unattended-upgrades"];
  }
}
