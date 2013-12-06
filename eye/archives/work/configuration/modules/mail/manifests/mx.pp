class mail::mx inherits postfix-base {
    case $enable_slow_queue { '': { $enable_slow_queue = false } }
    case $i_am_mx { '': { $i_am_mx = true } }
    case $greylist { '': { $greylist = false } }
    $files = "${files_root}/mail"

    $postfix_filter_limit = $postfix_filter_limit ? { '' => 4, default => $postfix_filter_limit } 

    postfix_file { "/etc/postfix/main.cf": content => template('mail/mx/main.cf.erb') }
    postfix_file { "/etc/postfix/master.cf": content => template('mail/mx/master.cf.erb') }
    postfix_db_file { 
        "/etc/postfix/transport": 
            source => "nodes/${hostname}/etc/postfix/transport";
        "/etc/postfix/rbl_whitelist": 
            source => "/rbl_whitelist",
            files_prefix => $files;
        "/etc/postfix/sender_access": 
            source => "/sender_access",
            files_prefix => $files;
    }
}

class mail::mx-server {
    $default_mta = false
    $postfix_mydestination = ["${hostname}.admin.alphalink.fr", "${hostname}.alphalink.fr", "localhost"]
    case $postfix_mynetworks { '': { $postfix_mynetworks = ["127.0.0.0/8", "169.254.65.0/24"] } }
    include mail::mx 
}

class mail::smtp {
  $default_mta = false
  $greylist = true
  $i_am_mx = false
  $postfix_mydestination = ["${hostname}", "localhost"]
  case $postfix_mynetworks { '': { $postfix_mynetworks = ["127.0.0.0/8", "169.254.65.0/24", "10.0.0.0/8"] } }
  include mail::mx
}
