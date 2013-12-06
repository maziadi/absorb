class erp_1_0::eligibility (
$active_mq_user_login , $active_mq_user_password , $active_mq_ip
){
  
  include monit
  package {
    [ "eligibilityd", "eligibility-bgd"
    ]: ensure => present;
  }

 
  file {
    "/etc/default/eligibilityd":
        content => template('erp_1_0/eligibility/eligibilityd.erb'),
        require => Package["eligibilityd"];
       # before => Service["eligibilityd"];
    "/etc/default/eligibility-bgd":
        content => template('erp_1_0/eligibility/eligibility-bgd.erb'),
        require => Package["eligibility-bgd"];
#        before => Service["eligibility-bgd"];
    "/etc/monitrc.d/eligibility":
        owner => root, group => root, mode => 700,
        notify => Service["monit"],
        source => "$files_root/erp_1_0/eligibility/monit",
        require => [Package["monit"],Package["eligibilityd"],Package["eligibility-bgd"]];
  }
  #service {
  #  "eligibilityd":
  #      enable => false,
  #      ensure => running,
  #      hasrestart => true;
  #  "eligibility-bgd":
  #      enable => false,
  #      ensure => running,
  #      hasrestart => true;
  #}
}
