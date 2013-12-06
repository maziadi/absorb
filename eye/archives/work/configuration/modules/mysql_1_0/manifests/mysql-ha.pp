class mysql_1_0::mysql-ha inherits mysql_1_0::mysql {
  Service["mysql"] {
    enable => false,
    ensure => undef
  }
}
