class samba::samba {
    package {
        [
            "samba",
            "smbclient"
        ] : ensure => present;
    }
   case $samba_ldap {
        true: {
            package {
        [
            "smbldap-tools",
            "ldap-server"
        ]: ensure => present;
            }
        }
    }
 
    case $samba_swat {
        true: {
            package {
                "swat": ensure => present;
            }
        }
    }
    
    case $samba_webmin {
        true: {
            package {
              [
                "libnet-ssleay-perl",
                "libauthen-pam-perl",
                "libio-pty-perl",
                "libmd5-perl"
              ]: ensure => present;
            }
        }
    }
    
    service {
        "samba":
            enable => true,
            ensure => running,
            hasrestart => true;
    }
    
    host_file { 
        "/etc/samba/smb.conf": 
            notify => Service["samba"] 
    }
}

class samba::pdc inherits samba::samba {
}
