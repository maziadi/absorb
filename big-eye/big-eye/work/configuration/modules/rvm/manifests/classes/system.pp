class rvm::system($version='latest') {

  include rvm::dependencies

  exec { 'system-rvm':
    path    => '/usr/bin:/usr/sbin:/bin',
    #command => "bash -c '/usr/bin/curl -s https://rvm.beginrescueend.com/install/rvm -o rvm-installer ; chmod +x rvm-installer ; rvm_bin_path=/usr/local/rvm/bin rvm_man_path=/usr/local/rvm/man ./rvm-installer --version ${version}'",
    command => "bash -c '/usr/bin/curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer -o rvm-installer ; chmod +x rvm-installer ; rvm_bin_path=/usr/local/rvm/bin rvm_man_path=/usr/local/rvm/man ./rvm-installer --version ${version}' stable",
    creates => '/usr/local/rvm/bin/rvm',
    require => [
      Class['rvm::dependencies'],
    ],
  }

}
