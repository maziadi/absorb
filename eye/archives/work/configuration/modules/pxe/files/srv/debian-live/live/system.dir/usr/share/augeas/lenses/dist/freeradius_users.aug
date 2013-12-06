
module Freeradius_users =
  autoload xfm

  let sep_tab = Util.del_ws_tab
  let eol     = Util.eol
  let empty   = Util.empty
  let comment = Util.comment
  let sep_coma = del /[ \t]*,[ \t]+/ ", "
  let sto_to_eol = store /([^\\ \t\n].*[^\\ \t\n]|[^\\ \t\n])/ . eol

  let word = /[^# \n\t,]+/


  let auth_type = [ key /Auth\-Type/ . del /[ \t]+:=[ \t]+/ " := " . store word ]
  let user_password = [ key /User\-Password/ . del /[ \t]+:=[ \t]+/ " := " . store word ]

  let framed_ip = [ key /[A-Za-z\-]+/ . del /[ \t]+=[ \t]+/ " = " . store word . del /[ \t]*,/ "," . eol ]
  let framed_ip2 = [ key /[A-Za-z\-]+/ . del /[ \t]+=[ \t]+/ " = " . store word . eol ]

  let entry = [ label "user" . store word . Util.del_ws " ". auth_type . sep_coma . user_password . eol .
      ( del /[ \t]*/ "\t" . framed_ip  )* . 
      ( del /[ \t]*/ "\t" . framed_ip2  )
    ]

  let record = entry  

  (* Define lens *)
  let filter = incl "/etc/freeradius/users"
             . Util.stdexcl
  let lns =  (comment|record|empty)*
  let xfm = transform lns filter


test lns get "toto@alphadev Auth-Type := Local, User-Password := za\n\tFramed-IP-Address = 192.168.0.1,\n\tFall-Through = No\n" = 
  { "user" = "toto@alphadev"
    { "Auth-Type" = "Local"  }
    { "User-Password" = "za"  }
    { "Framed-IP-Address" = "192.168.0.1" }
    { "Fall-Through" = "No" }
  }
  
