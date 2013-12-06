class repository_0_0::lisos {
  include repository_0_0::apache
  define create_repo_lisos($test=true){
    file {
      "${packages_dir}/${name}":
        owner => root, group => root, mode => 755,
        ensure => directory;
      "${packages_dir}/${name}/lisos2":
        owner => root, group => root, mode => 755,
        ensure => directory;
    }
  }
}
