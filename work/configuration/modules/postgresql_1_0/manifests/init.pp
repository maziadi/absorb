class postgresql_1_0::client (
  $client_package = $postgresql_1_0::params::client_package,
  $version = $postgresql_1_0::params::version

) inherits postgresql_1_0::params {

  package { "postgresql-client-$version":
    name    => sprintf("%s-%s", $client_package, $version),
    ensure  => present,
  }
}
