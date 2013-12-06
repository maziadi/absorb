class system_1_0::sun-jdk {
  $debconf_set_selections = template("system_1_0/debian/sun-debconf.erb")
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

class system_1_0::sun-jdk6 {
  $debconf_set_selections = template("system_1_0/debian/sun6-debconf.erb")
  exec {
    "initialize debconf":
      command => "echo '^${debconf_set_selections}' | debconf-set-selections",
      unless => "dpkg -l sun-java6-jdk | grep -q '^ii.*sun-java6-jdk'",
      before => Package["sun-java6-jdk"];
    "change alternative":
      command => "update-alternatives --set java /usr/lib/jvm/java-6-sun/jre/bin/java",
      require => Package["sun-java6-jdk"],
      unless => "update-alternatives --query java  | grep -q 'Status: manual'"
  }
  package { "sun-java6-jdk" : ensure => present }
}
