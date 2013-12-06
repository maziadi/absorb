class rvm::dependencies {
  case $operatingsystem {
    Debian: { require rvm::dependencies::debian }
    Ubuntu: { require rvm::dependencies::ubuntu }
    CentOS,RedHat: { require rvm::dependencies::centos }
  }
}
