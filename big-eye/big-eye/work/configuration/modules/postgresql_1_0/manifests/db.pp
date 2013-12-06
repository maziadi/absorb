define postgresql_1_0::db (
    $password,
    $owner = $name,
    $encoding = 'UTF8',
    $locale = 'en_US.UTF-8')
{

    pg_user {$owner:
        ensure      => present,
        password    => $password,
        superuser   => true,
        createdb    => true,
        createrole  => true,
    }

    pg_database {$name:
        ensure      => present,
        owner       => $owner,
        require     => Pg_user[$owner],
        encoding    => $encoding,
        locale      => $locale,
    }
}

define postgresql_1_0::schema (
    $db,
    $username,
    $password,
    $file,
    $check_table, 
    $check_column=nil )
{

  pg_fill {$name:
    ensure        => present,
    database      => $db,
    external_file => $file,
    check_table   => $check_table,
    check_column   => $check_column,
  }
}
