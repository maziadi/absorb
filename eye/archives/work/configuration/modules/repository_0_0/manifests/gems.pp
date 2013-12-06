class repository_0_0::gems {
  include repository_0_0::apache 
  package {
    "rubygems":
      ensure => present,
  }

  file {
    "${packages_dir}/gems":
      owner => root, group => root, mode => 755,
      ensure => directory,
      require => File["${packages_dir}"];
    "${packages_dir}/gems/gems":
      owner => root, group => root, mode => 755,
      ensure => directory,
      require => File["${packages_dir}/gems"];
  }
}
