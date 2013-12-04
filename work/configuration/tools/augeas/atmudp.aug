module Atmudp =
  autoload xfm


(************************************************************************
 *                           USEFUL PRIMITIVES
 *************************************************************************)

let eol        = Util.eol
let spc        = Util.del_ws_spc
let comment    = Util.comment
let empty      = Util.empty

let sep_eq     = del /[ \t]*=[ \t]*/ "="
let colon      = del /:/ ":"
let dash       = del /[ \t]+-[ \t]+/ " - "
let sto_to_eol = store /([^ \t\n].*[^ \t\n]|[^ \t\n])/
let sto_num    = store /([0-9]+)/
let sto_word   = store /([a-z]+)/
let id         = [ label "id" . sto_num ]
let ip         = [ label "ip" . store /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/ ]
let port       = [ label "port" . sto_num ]
let version    = [ label "version" . store /([0-1])/ ]
let ip_port    = ip . colon . port
let mac        = [ label "mac" . store /([0-9A-Z]+)/ ]
let qos_route  = [ label "qos" . store /([a-z0-9A-Z\.]+)/ ]
let type       = [ label "type" . store /([a-z0-9A-Z]+)/ ]


(************************************************************************
 *                               ENTRIES
 *************************************************************************)

let daemon_data =  id 
		. colon
		. ip_port
 
let daemon      = [ key /DAEMON/ . sep_eq . daemon_data . eol ]

let itf_data    =  store /([a-z\_]+)/ . colon . id .
		(
			( (* xsdevice *)
			 	colon
				. [ label "atmid" . sto_num ] . colon 
				. [ label "atmport" . sto_num ] . colon 
				. [ label "ethport" . sto_num ] . colon
				. [ label "daemon" . sto_num ]
				. ( colon . [ label "mtu" . sto_num ] )?
				
			) | (   (* xs_embeded *)
				colon
				.  [ label "atmid" . sto_num ] . colon 
				. ip . colon
				. [ label "port" . sto_num ] . colon
				. [ label "ethid" . sto_num ] 
			) | (   (* xs_embeded *)
				colon
				.  [ label "atmid" . sto_num ] . colon 
				. [ label "atmport" . sto_num ] . colon 
				. [ label "ethport" . sto_num ] . colon 
				. ip . colon
				. [ label "port" . sto_num ] . colon
				. [ label "ethid" . sto_num ] 
			) | ( (* socket *) 
				colon 
        . ip . colon
        . ( mac . colon )?
        . port . colon
				. [ label "daemon" . sto_num ]
	      (* . ( colon . version )? utile? provoque une ambiguite *)
			) | ( (* eth *)
				colon . [ label "name" . sto_word ]
			)
		)?

let itf         = [ key /ITF/ . sep_eq . itf_data . eol ]

let qos         = [ key /QOS/ . sep_eq . sto_to_eol . eol ]


let route_addr  = [ label "itf" . sto_num ]
		. del /\./ "." 
		. ( (
			 [ label "vp" . sto_num ]
			. del /\./ "."
			. [ label "vc" . sto_num  ]
			. ( del /\-/ "-" . qos_route  )?
		) | (
			 [ label "vlan" . sto_num ]
			. ( del /\-/ "-" .  type  . del /\./ "." . qos_route  )?
		) )
let route_data  = [ label "vcc" .  route_addr ] 
		. colon 
		. [ label "vcc" . route_addr ] .
    ( colon . [ qos_route ] )?

let route       = [  key /ROUTE/ . sep_eq . route_data . eol ]

let xsmod  = [ key /XS\_module/ . sep_eq . sto_to_eol . eol ]

let xsopt  = [ key /XS\_options/ . sep_eq . sto_to_eol . eol ]

let entry       = daemon | itf | qos| route | xsmod | xsopt

(************************************************************************
 *                                LENS
 *************************************************************************)

let lns = (empty|comment|entry) *

let xfm = transform lns (incl "/etc/network/atmudp")


test lns get "DAEMON=0:169.254.2.1:2600\n" = 
	{ "DAEMON" 
		{ "id" = "0" }
		{ "ip" = "169.254.2.1" }
		{ "port" = "2600" }
	}

test lns get "ITF=socket:64:83.167.130.174:2600:1\n" = 
	{ "ITF" = "socket"
		{ "id" = "64" }
		{ "ip" = "83.167.130.174" }
		{ "port" = "2600" }
		{ "daemon" = "1" }
	}
test lns get "ITF=xs_device:12:0:0:12:32:0\n" = 
	{ "ITF" = "xs_device"
		{ "id" = "12" }
		{ "atmid" = "0" }
		{ "atmport" = "0" }
		{ "ethport" = "12" }
		{ "daemon" = "32" }
    { "mtu" = "0" }
	}

test lns get "ITF=xs_embeded:0:0:0:0:169.254.2.2:32:0\n" =
	{ "ITF" = "xs_embeded"
		{ "id" = "0" }
		{ "atmid" = "0" }
		{ "atmport" = "0" }
		{ "ethport" = "0" }
    { "ip" = "169.254.2.2" }
		{ "port" = "32" }
    { "ethid" = "0" }
	}


test lns get "ITF=tap:91\n" = 
	{ "ITF" = "tap"
		{ "id" = "91" }
	}

test lns get "ROUTE = 0.0.102:95.0.34-2C250\n" = 
	{ "ROUTE" 
		{ "vcc" 
			{ "itf" = "0" }
			{ "vp" = "0" }
			{ "vc" = "102" }
		}
		{ "vcc" 
			{ "itf" = "95" }
			{ "vp" = "0" }
			{ "vc" = "34" }
			{ "qos" = "2C250" }
		}
	} 

test lns get "ROUTE = 0.12:55.987\n" = 
	{ "ROUTE" 
		{ "vcc" 
			{ "itf" = "0" }
			{ "vlan" = "12" }
		}
		{ "vcc" 
			{ "itf" = "55" }
			{ "vlan" = "987" }
		}
	} 
test lns get "ROUTE = 0.12-12aze.78:55.987\n" = 
	{ "ROUTE" 
		{ "vcc" 
			{ "itf" = "0" }
			{ "vlan" = "12" }
			{ "type" = "12aze" }
			{ "qos" = "78" }
		}
		{ "vcc" 
			{ "itf" = "55" }
			{ "vlan" = "987" }
		}
	} 

test lns get "ROUTE = 0.0.102:95.0.34\n" = 
	{ "ROUTE"
		{ "vcc" 
			{ "itf" = "0" }
			{ "vp" = "0" }
			{ "vc" = "102" }
		}
		{ "vcc" 
			{ "itf" = "95" }
			{ "vp" = "0" }
			{ "vc" = "34" }
		}
	}

