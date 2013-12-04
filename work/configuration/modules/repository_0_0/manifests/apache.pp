class repository_0_0::apache {
  include apache
  file {
    "${packages_dir}":
      owner => root, group => root, mode => 755,
      ensure => directory;
    "${packages_dir}/livrables":
      owner => root, group => root, mode => 755,
      ensure => directory;
    "/data/.htpasswd-packages":
      owner => root, group => root, mode => 755,
      require => File["${packages_dir}"],
      source => "${files_root}/repository_0_0/apache/htpasswd";
    "/data/.htpasswd-livrables":
      owner => root, group => root, mode => 755,
      require => File["${packages_dir}"],
      source => "${files_root}/repository_0_0/apache/htpasswd-livrables";
  } 
  define repo_apache_virtual_server() {
      $server_name = $name
      $document_root = "${packages_dir}"
      apache_virtual_server {
        "${server_name}": 
            content => template('repository_0_0/apache/site.erb');
      }
  }
}
