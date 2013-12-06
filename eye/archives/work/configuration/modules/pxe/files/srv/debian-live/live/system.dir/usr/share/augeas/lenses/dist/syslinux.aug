module Syslinux =
	autoload xfm

	let value_to_eol = store /[^= \t][^\n]*/
	let eol = Util.del_str "\n"
	let del_to_eol = del /[^\n]*/ ""
	let opt_ws = Util.del_opt_ws ""
	let value_sep (dflt:string) = del /[ \t]*[ \t=][ \t]*/ dflt
	let empty = Util.empty
	let kw_arg (kw:string) (indent:string) (dflt_sep:string) = [ Util.del_opt_ws indent . key kw . value_sep dflt_sep . value_to_eol . eol ]
	let kw_boot_arg (kw:string) = kw_arg kw "\t" " "
	let kw_menu_arg (kw:string) = kw_arg kw "" " "

	let kw_pres (kw:string) = [ opt_ws . key kw . del_to_eol . eol ]

	let menu_setting = kw_menu_arg "prompt"
                     | kw_menu_arg "timeout"
                     | kw_menu_arg "default"

	let bel = del /LABEL[ \t]+/ "LABEL " . value_to_eol . eol

	let boot_setting = kw_boot_arg "kernel"
                     | kw_boot_arg "append"  

	let boot = [ label "label" . bel . boot_setting* ]


	let lns = (empty | menu_setting | boot)*
  let filter = (incl "/syslinux/syslinux.cfg") . (incl "/boot/syslinux/syslinux.cfg") 
                . (incl "/live/image/syslinux/syslinux.cfg") . Util.stdexcl
	let xfm = transform lns filter 
 
