class gitolite_1_0::gitolite {

  package {
    "git":
      ensure => present;
    "gitolite":
      ensure => present;
  }

}
