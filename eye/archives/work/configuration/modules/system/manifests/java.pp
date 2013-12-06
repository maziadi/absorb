class system::sun-jdk {
  $debconf_set_selections = template("system/debian/sun-debconf.erb")
  exec {
    "initialize debconf":
      command => "echo '^${debconf_set_selections}' | debconf-set-selections",
      unless => "dpkg -l sun-java5-jdk | grep -q '^ii.*sun-java5-jdk'",
      before => Package["sun-java5-jdk"];
    "change alternative":
      command => "update-alternatives --set java /usr/lib/jvm/java-1.5.0-sun/jre/bin/java",
      require => Package["sun-java5-jdk"];
  }
  package { "sun-java5-jdk" : ensure => present }
}

class system::sun-jdk6 {
  $debconf_set_selections = template("system/debian/sun6-debconf.erb")
  exec {
    "initialize debconf":
      command => "echo '^${debconf_set_selections}' | debconf-set-selections",
      unless => "dpkg -l sun-java6-jdk | grep -q '^ii.*sun-java6-jdk'",
      before => Package["sun-java6-jdk"];
    "change alternative":
      command => "update-alternatives --auto java",
      require => Package["sun-java6-jdk"];
  }
  package { "sun-java6-jdk" : ensure => present }
}
