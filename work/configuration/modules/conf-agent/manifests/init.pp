# Alphalink conf-agent
class conf-agent::conf-agent inherits nginx {
 
  case $conf_agent_http_port           {'': { $conf_agent_http_port = '80' } }
  case $conf_agent_server_name         {'': { $conf_agent_server_name = '0.0.0.0' } }

  case $conf_agent_directory           {'': { $conf_agent_directory = '/usr/share/conf-agent' } }
  case $conf_agent_port                {'': { $conf_agent_port = '8000' } }
  case $conf_agent_mongrel_servers     {'': { $conf_agent_mongrel_servers = '1' } }
  case $conf_agent_proxy               {'': { $conf_agent_proxy = false } }
  case $conf_agent_zimbra               {'': { $conf_agent_zimbra = false } }


  include nginx
  package { 
    [
      "conf-agent",
      "rake",
      "libpam-ldap",
      "ldap-utils",
      "mongrel",
      "mongrel-cluster"
    ]:
        ensure => present,
        before => Service["mongrel-cluster"];
  }

  config_file {
    "/etc/mongrel-cluster/sites-enabled/conf-agent.yml":
        content => template('conf-agent/conf-agent.yml.erb'),
        require => Package["mongrel-cluster"],
        before => Service["mongrel-cluster"];
    "/etc/nginx/sites-enabled/conf-agent":
        content => template('conf-agent/conf-agent-nginx.erb'),
        require => Package["nginx"],
        before => Service["nginx"],
        notify => Service["nginx"];
  }
          
  service {
    "mongrel-cluster":
        enable => true,
        ensure => running,
        hasrestart => true,
        pattern => '/mongrel_rails';
  }
  file {
#    "/etc/nginx/sites-enabled/default":
#        ensure => absent,
#        before => Service["nginx"],
#        notify => Service["nginx"];
    "/etc/default/mongrel-cluster":
        source => "${files_root}/conf-agent/default-mongrel-cluster",
        mode => 644, owner => root, group => root,
        before => Service["mongrel-cluster"],
        notify => Service["mongrel-cluster"];

  }
}

class conf-agent::proxy {
  # Case pour sarg, temps durant lequel on garde les logs
  case $lastlog_time                   { '': { $lastlog_time = '52' } }
  $conf_agent_proxy = true
  
  include clamav
  include conf-agent::conf-agent
  
  package { 
    [
      "squid3",
      "sarg",
      "dansguardian",
      "lynx"
    ]:
        ensure => present,
        before => Service["mongrel-cluster"];
  }
  config_file {
    "/etc/squid/sarg.conf":
        content => template('conf-agent/sarg.conf.erb'),
        require => Package["sarg"];
    "/etc/squid/sarg-reports.conf":
        content => template('conf-agent/sarg-reports.conf.erb'),
        require => Package["sarg"];
  }
}

class conf-agent::zimbra {

  $conf_agent_zimbra = true
  $conf_agent_http_port = '8080'

  include conf-agent::conf-agent
  
}

class conf-agent::all {
  include conf-agent::zimbra
  include conf-agent::proxy
}
