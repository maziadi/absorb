(* iproute2/rt_tables module for Augeas          *)

module Rt_tables =
  autoload xfm

  let sep_tab = Util.del_ws_tab
  let eol     = Util.eol
  let empty   = Util.empty
  let comment = Util.comment

  let filter = incl "/etc/iproute2/rt_tables"
             . Util.stdexcl

  let word = /[^# \n\t]+/
  let id   = /[0-9]+/

  let record = [ key id . sep_tab . store  word ] . eol

  (* Define lens *)
  let lns =  (comment|record|empty)*
  let xfm = transform lns filter


