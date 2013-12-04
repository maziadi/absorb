module Profile_ppp =

autoload xfm

(************************************************************************
*                           USEFUL PRIMITIVES
*************************************************************************)

let eol        = Util.eol
let spc        = Util.del_ws_spc
let comment    = Util.comment
let empty      = Util.empty

let sep     = del /[ \t]+/ " "
let sto_to_eol = store /([^\\ \t\n].*[^\\ \t\n]|[^\\ \t\n])/ . eol

(************************************************************************
*                               ENTRIES
*************************************************************************)
let entry_re   = /[A-Za-z0-9_-]+/
let entry      = [ key entry_re . sep . sto_to_eol  ]

(************************************************************************
*                                LENS
*************************************************************************)

let lns = (comment|empty|entry) *

let filter            = incl "/etc/ppp/profiles/*"
  . Util.stdexcl

let xfm                = transform lns filter


let conf = "isolate 2
name ppp254002
up ip route add default dev $IFNAME
"
test lns get conf =
{ "isolate" = "2" }
{ "name" = "ppp254002" }
{ "up" = "ip route add default dev $IFNAME" }
