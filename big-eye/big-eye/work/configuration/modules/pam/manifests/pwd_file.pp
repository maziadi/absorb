define pam::pwd_file($file) {
    $pam_pwd_file = $file
    config_file {
        "/etc/pam.d/${name}": 
            content => template('pam/pam_file_config.erb'),
            require => Class[pwdfile];
    }
}
