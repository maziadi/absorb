# Module erp pour l'installation de SI
class erp::erp {
    $mysql_create_lv = "true"
    $mysql_bind_address = "0.0.0.0"

    include mysql_1_0::mysql

    mysql_1_0::mysql::mysql_db {
        "erp_production":
            username => "erp",
            password => "Shah0ras12";
        "erptech_production":
            username  => "erptech",
            password  => "Ir3ca1d83";
    }
    
    case $default_www_directory   {'': { $default_www_directory = "/usr/share/erp/" } }
    case $erp_port                {'': { $erp_port = "8000" } }
    case $erp_mongrel_servers     {'': { $erp_mongrel_servers = "6" } }

    $erp_directory = $default_www_directory
    include nginx

    package {
        [
            "nsis",
            "eligibilityd",
            "eligibility-bgd",
            "erp",
            "irb",
            "git-core",
            "mongrel",
            "mytop",
            "mongrel-cluster",
            "libmysql-ruby1.8",
            "rake"
        ]: ensure => present;
    }
    
    config_file {
        "/etc/mongrel-cluster/sites-enabled/erp-init.yml":
            content => template('erp/erp-init.yml.erb'),
            require => Package["mongrel-cluster"],
            before => Service["mongrel-cluster"];
        "/etc/erp/broker.yml":
            content => template('erp/broker.yml.erb'),
            require => Package["erp"];
        "/etc/default/eligibilityd":
            content => template('erp/eligibilityd.erb'),
            require => Package["eligibilityd"],
            before => Service["eligibilityd"];
        "/etc/default/eligibility-bgd":
            content => template('erp/eligibility-bgd.erb'),
            require => Package["eligibility-bgd"],
            before => Service["eligibility-bgd"];
    }
    file {
      "/etc/logrotate.d/erp":
        owner => root, group => root, mode => 644,
        source => "${files_root}/erp/logrotate_erp",
        require => Package["erp"];
    }

    service {
        "mongrel-cluster":
            enable => true,
            ensure => running,
            hasrestart => true,
            pattern => '/mongrel_rails';
        "eligibilityd":
            enable => true,
            ensure => running,
            hasrestart => true;
        "eligibility-bgd":
            enable => true,
            ensure => running,
            hasrestart => true;
    }
}
