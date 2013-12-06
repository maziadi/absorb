# Classe pour l'installation de proxy
#
# La classe proxy_1_0::proxy définit la brique logicielle utilisée pour cette fonction
#
# Le modèle de base est proxy_1_0::dansguardian qui integre un proxy dasnguardian et un
# proxy squid
#
# La classe proxy_1_0::client_config définit que le proxy est configuré par le client
#

class proxy_1_0::proxy {
    include proxy_1_0::dansguardian
}

class proxy_1_0::standard {
    include proxy_1_0::proxy
    include proxy_1_0::client_config
    include rsyslog_1_0::rsyslog-client
    include monit
    pam::pwd_file { "squid": file => "/data/directory/proxy.passwd" }
  include pam::pwdfile
}

class proxy_1_0::standard_antivirus {
    include proxy_1_0::standard
    include clamav
}

class proxy_1_0::dansguardian {
    # Global variable default values
    case $proxy_ip {'': { $proxy_ip = '127.0.0.1' } }
    case $dansguardian_ip {'': { $dansguardian_ip = false } }
    case $dansguardian_port {'': { $dansguardian_port = '8080' } }
    case $dansguardian_proxy_port {'': { $dansguardian_proxy_port = '3128' } }
    case $dansguardian_auth_plugins { '': { $dansguardian_auth_plugins = true } }  # pour l'authentification IP
    case $proxypac {'': { $proxypac = false } }


    include proxy_1_0::squid
    package {
        [
          "lynx",
          "dansguardian"
        ]: 
            ensure => latest;
    }

     file {
          "/etc/dansguardian/lists":
          owner => root, group => root,
          source => [
              "${dist_files}/nodes/${hostname}/etc/dansguardian/lists",
              "${files_root}/proxy_1_0/lists",
            ],
          sourceselect => all,
          require => Package["dansguardian"],
          before  => Service["dansguardian"],
          notify  => Service["dansguardian"],
          ensure => directory,
          recurse => true;
    }
     file {
          "/etc/dansguardian/authplugins/ip.conf":
          owner => root, group => root,
          source => "${files_root}/proxy_1_0/ip.conf",
          require => Package["dansguardian"],
          before  => Service["dansguardian"],
          notify  => Service["dansguardian"],
    }

    file {
        "/var/www/":
        owner => root,
        ensure => directory,
    }

    case $proxypac {
      true: {
        file {
          "/var/www/proxy.pac":
            owner => root, group => root, mode => 644,
            source => "${dist_files}/nodes/${hostname}/proxy.pac",
            require => [File["/var/www"], Package["dansconfig"]];
        }
      }
      false: {
        file {
          "/var/www/proxy.pac":
            owner => root, group => root, mode => 644,
            content => template('proxy_1_0/proxy.pac.erb'),
            require => [File["/var/www"], Package["dansconfig"]];
        }
      }
    }
    config_file {
      "/etc/logrotate.d/dansguardian":
        content => template('proxy_1_0/dansguardian_logrotate.erb'),
        ensure => present; 
      "/etc/dansguardian/dansguardian-pre.conf":
        content => template('proxy_1_0/dansguardian.conf.erb'),
        ensure => present;
      "/etc/lynx-cur/local.cfg":
        content => template('proxy_1_0/local.cfg.erb'),
        require => Package["lynx"];
    }
    service {
        "dansguardian":
            enable => true,
            ensure => running;
    }
}

class proxy_1_0::client_config {
  include nginx
  include monit
  case $dansconfig_env { '': { $dansconfig_env = "development" } }
  case $dansconfig_net { '': { $dansconfig_net = "0.0.0.0/0" } }
  case $dansconfig_crypted { '': { $dansconfig_crypted = false } }
  case $dansconfig_format { '': { $dansconfig_format = "xls" } }
  # TODO install code file
#  $appli_dir = "/var/www/proxy-admin/"
  #file {
#	  source => "${files_root}/proxy_1_0/configurator"
#  }

    case $proxy_blacklist_toulouse {'': { $proxy_blacklist_toulouse = false } }

    if $proxy_blacklist_toulouse {
        file {
        "/data/toulouse":
          owner => root, group => root, mode => 755,
          require => File["/data"],
          ensure => directory;
        }
         exec{
          "download_toulouse_blacklist":
             cwd     => "/root",
             command => "rsync -arpogt rsync://ftp.ut-capitole.fr/blacklist/dest/ /data/toulouse",
             timeout => 3600,
             unless  => "test -f /data/toulouse/global_usage",
             require => File["/data/toulouse"];
        }
        cron {
          "maj_blacklist_toulouse":
            command =>"rsync -arpogt rsync://ftp.ut-capitole.fr/blacklist/dest/ /data/toulouse",
            user => root,
            hour => '22',
            minute => '1';
        }
    }

  file {
        "/etc/dansconfig/unicorn.rb":
          owner => root, group => root, mode => 644,
          content => template('proxy_1_0/unicorn.rb.erb'),
          require => [Package["dansconfig"]];
        "/etc/dansconfig/dansconfig.yaml":
          owner => root, group => root, mode => 644,
          content => template('proxy_1_0/dansconfig.yaml.erb'),
          require => [Package["dansconfig"]];
        "/srv/dansconfig/config/unicorn.rb":
          ensure => link,
          require => File["/etc/dansconfig/unicorn.rb"],
          target => "/etc/dansconfig/unicorn.rb";
        "/etc/nginx/sites-enabled/dansconfig":
          owner => root, group => root, mode => 755,
          content => template('proxy_1_0/dansconfig.nginx.erb'),
          notify => Service["nginx"],
          require => Package["nginx"];
        "/etc/monitrc.d/unicorn":
          owner => root, group => root, mode => 700,
          content => template('proxy_1_0/monit_unicorn.erb'),
          notify => Service["monit"],
          require => [Package["monit"],Package["unicorn"]];
        "/var/run/dansconfig":
          owner => dansconfig, group => dansconfig, mode => 755,
          require => Package["dansconfig"],
          ensure => directory;
        "/etc/dansguardian/":
      	  owner => dansconfig,
          require => Package["dansconfig"],
          ensure => directory,
          recurse => true;
        "/srv/dansconfig/templates/configurator":
          owner => root, group => root, mode => 755, recurse=> true,
          source => "${files_root}/proxy_1_0/configurator",
          require => [Package['dansconfig']];
        "/srv/dansconfig/tmp":
          owner => dansconfig, group => dansconfig,
          ensure => directory,
          require => [Package['dansconfig']];
        "/srv/dansconfig/tmp/sockets":
          owner => dansconfig, group => dansconfig,
          ensure => directory,
          require => File['/srv/dansconfig/tmp'];
        "/data/directory":
          owner => dansconfig, group => dansconfig,recurse=> true,
          ensure => directory;
        "/etc/dansconfig/htpasswd":
          owner => root, group => www-data, mode => 640,
          source => [
              "${dist_files}/nodes/${hostname}/etc/dansconfig/htpasswd",
              "${files_root}/proxy_1_0/htpasswd",
            ],
          sourceselect => first,
          require => [Package['dansconfig','nginx']];
  }
  package {
    [
      "rubygems", "dansconfig", "unicorn", "psmisc"
    ]:
       ensure => present
  }

}

class proxy_1_0::squid {
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
  case $squid_no_authentication_net { '': {$squid_no_authentication_net = false}}
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
      "squid3"
    ]: 
      ensure => present,
      before => Service["squid3"];
  }
  config_file {
    "/etc/squid3/squid.conf":
      content => template("proxy_1_0/squid.conf.erb"),
      notify => Service["squid3"],
      before => Service["squid3"],
      require => Package["squid3"];
  }
  service {
    "squid3":
      enable => true,
      ensure => running,
  }
}
