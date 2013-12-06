class pam::pwdfile {
    package {
        "libpam-pwdfile": ensure => present;
    }
}

class pam::directory {
    # les variables suivantes sont indispensables (5 params a definir):
    # $pam_directory_ip = "10.10.10.10"
    # $pam_directory_uri = "host.domain.com"
    # $pam_directory_bindpw = "password"
    # pour AD
    # $pam_directory_base = "cn=Users,dc=domain,dc=com"
    # $pam_directory_binddn = "cn=Administrateur,cn=Users,dc=domain,dc=com"
    # Pour LDAP
    # $pam_directory_base = "ou=Users,ou=OxObjects,dc=domain,dc=com"
    # $pam_directory_binddn = "cn=admin,dc=domain,dc=com"

    case $pam_ad { '': { $pam_ad = false } }

    package {
        [
            "libpam-ldap",
            "ldap-utils"
        ]: ensure => present;
    }
    config_file {
        "/etc/ldap/ldap.conf":
            content => template('pam/ldap.conf.erb'),
            require => Package[libpam-ldap];
        "/etc/pam_ldap.conf":
            content => template('pam/pam_ldap.conf.erb'),
            require => Package[libpam-ldap];
        "/etc/pam_ldap.secret":
            content => template('pam/pam_ldap.secret.erb'),
            mode => 600,
            require => Package[libpam-ldap];
        "/etc/pam.d/squid":
            content => template('pam/squid.erb'),
    }
}
