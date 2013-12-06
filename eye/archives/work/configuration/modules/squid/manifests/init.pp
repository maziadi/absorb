# Installation de squid 3
#
# $squid_is_transparent : si vraie, le proxy est installe en transparent.
# $squid_safe_ports : une liste de ports supplementaires a accepter.
class squid::squid {

  # Include de nginx pour rapport d'utilisation via sarg, conf agent et proxy-pac
  # pour inclure un proxy.pac, creer un host_file dans le node concerne
  case $squid_proxypac { '': { $squid_proxypac = false } }
  case $sarg_auth_basic { '': { $sarg_auth_basic = false } }
  case $sarg_auth_file { '': { $sarg_auth_file = "/etc/nginx/sites-enabled/.sarg_htpasswd" } }
  case $conf_agent_nginx {'': { $conf_agent_nginx = false } }
  case $nginx_port {'': { $nginx_port = '80' } }
  case $nginx_servername {'': { $nginx_servername = 'localhost' } }
  config_file {
    "/etc/nginx/sites-enabled/proxy-alphalink" :
    notify => Service["nginx"],
    content => template('nginx/proxy-alphalink.erb'),
    require => Package["nginx"],
    before => Service["nginx"];
  }
  
  
  $default_www_directory = "/var/www/squid-reports"
  include nginx

  case $listen_address {'': { $listen_address = '127.0.0.1' } }
  case $squid_other_port {'': { $squid_other_port = '3128' } }
  case $squid_is_transparent { '': { $squid_is_transparent = false } }
  case $squid_has_cache { '': { $squid_has_cache = false } }
  case $squid_cache_mem { '': { $squid_cache_mem = "8 MB" } }
  case $squid_maximum_object_size { '': { $squid_maximum_object_size = "4096 KB" } }
  case $squid_request_body_max_size { '': { $squid_request_body_max_size = "0 KB"} }
  case $squid_url_rewrite_children { '': { $squid_url_rewrite_children = '5'} }
  
  case $squid_safe_ports { '': { $squid_safe_ports = []} }
  case $squid_ssl_ports { '': { $squid_ssl_ports = [] } }
  
  case $squid_has_authentication { '': { $squid_has_authentication = false } }
  case $squid_authentication_realm { '': { $squid_authentication_realm = "Authentification proxy" } }
  # Utilisé pour la génération de règles
  case $squid_http_access { '': { $squid_http_access = [] } }
  case $squid_http_deny { '': { $squid_http_deny = [] } }
  case $squid_acls { '': { $squid_acls = [] } }
  case $squid_dstdom_regexs { '': { $squid_dstdom_regexs = [] } }

  case $squid_visible_hostname {'': { $squid_visible_hostname = false } }

  # Case pour sarg, temps durant lequel on garde les logs
  case $lastlog_time { '': { $lastlog_time = '52' } }

  package { 
    [
      "squid3",
      "sarg"
    ]: 
      ensure => present,
      before => Service["squid3"];
  }
  config_file {
    "/etc/squid3/squid.conf":
      content => template("squid/squid.conf.erb"),
      notify => Service["squid3"],
      before => Service["squid3"],
      require => Package["squid3"];
    "/etc/squid/sarg.conf":
      content => template("squid/sarg.conf.erb"),
      require => Package["sarg"];
    "/etc/squid/sarg-reports.conf":
      content => template("squid/sarg-reports.conf.erb"),
      require => Package["sarg"];
  }
  file {
    "/etc/cron.monthly/sarg":
      owner => root, group => root, mode => 755,
      source => "${files_root}/squid/etc/cron.monthly/sarg";
    "/usr/sbin/sarg-reports":
      owner => root, group => root, mode => 755,
      source => "${files_root}/squid/usr/sbin/sarg-reports"; 
  }
      
  service {
    "squid3":
      enable => true,
      ensure => running,
  }
}
