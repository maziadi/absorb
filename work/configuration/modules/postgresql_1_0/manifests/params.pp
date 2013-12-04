class postgresql_1_0::params {
  case $::operatingsystem {
    /(Ubuntu|Debian)/: {
      $version = '9.1'
      $client_package = 'postgresql-client'
      $server_package = 'postgresql'
      $server_dev_package = 'postgresql-server-dev'
      $listen_address = '*'
      $port = 5432
      $postgresql_max_connections = 100
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
