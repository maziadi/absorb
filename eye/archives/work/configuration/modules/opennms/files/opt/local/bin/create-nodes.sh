#!/bin/bash
#/usr/share/opennms/bin/provision.pl list

/usr/share/opennms/bin/provision.pl requisition add Alphalink 

# set up the first node 
/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid1 "bc-voip-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid1 comment "VOIP"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid1 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid1 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid1 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid1 217.15.80.161   
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid1 217.15.80.161   snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid1 217.15.80.161   descr "VOIP-1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid1 217.15.80.161   ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid1 217.15.80.161   SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.161 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid2 "bc-voip-1-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid2 comment "VOIP"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid2 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid2 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid2 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid2 217.15.88.161  
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid2 217.15.88.161  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid2 217.15.88.161  descr "VOIP-2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid2 217.15.88.161  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid2 217.15.88.161  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.88.161 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid3 "bc-voip-1-ext1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid3 comment "VOIP"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid3 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid3 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid3 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid3 217.15.88.162  
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid3 217.15.88.162  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid3 217.15.88.162  descr "bc-VOIP-1-ext1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid3 217.15.88.162  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid3 217.15.88.162  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.88.162 78Ggruzg4p timeout=30000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid4 "gw-isdn-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid4 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid4 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid4 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid4 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid4 217.15.80.250 
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid4 217.15.80.250  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid4 217.15.80.250  descr "gw-ISDN-1-cbv1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid4 217.15.80.250  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid4 217.15.80.250  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.250 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid5 "gw-isdn-2-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid5 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid5 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid5 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid5 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid5 217.15.88.251
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid5 217.15.88.251  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid5 217.15.88.251  descr "gw-ISDN-2-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid5 217.15.88.251  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid5 217.15.88.251  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.88.251 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid6 "gw-isdn-3-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid6 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid6 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid6 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid6 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid6 217.15.80.253
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid6 217.15.80.253  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid6 217.15.80.253  descr "gw-ISDN-3-cbv1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid6 217.15.80.253  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid6 217.15.80.253  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.253 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid7 "gw-isdn-3-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid7 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid7 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid7 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid7 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid7 217.15.88.253
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid7 217.15.88.253  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid7 217.15.88.253  descr "gw-ISDN-3-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid7 217.15.88.253  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid7 217.15.88.253  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.88.253 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid8 "gw-voip-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid8 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid8 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid8 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid8 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid8 217.15.80.248
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid8 217.15.80.248  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid8 217.15.80.248  descr "gw-VOIP-1-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid8 217.15.80.248  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid8 217.15.80.248  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.248 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid9 "gw-voip-1-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid9 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid9 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid9 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid9 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid9 217.15.88.248
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid9 217.15.88.248  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid9 217.15.88.248  descr "gw-VOIP-1-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid9 217.15.88.248  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid9 217.15.88.248  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.88.248 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid10 "san-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid10 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid10 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid10 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid10 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid10 169.254.0.89
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid10 169.254.0.89  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid10 169.254.0.89  descr "san-1-cbv1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid10 169.254.0.89  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid10 169.254.0.89  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   169.254.0.89 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid11 "san-1-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid11 comment "ISDN"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid11 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid11 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid11 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid11 169.254.1.89
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid11 169.254.1.89  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid11 169.254.1.89  descr "san-1-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid11 169.254.1.89  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid11 169.254.1.89  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   169.254.1.89 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid12 "mon-1-grp-alpha" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid12 comment "localhost"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid12 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid12 building ""
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid12 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid12 217.15.80.78
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid12 217.15.80.78  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid12 217.15.80.78  descr "mon-1-grp-alpha"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid12 217.15.80.78  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid12 217.15.80.78  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.78 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid13 "si-3-pornic" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid13 comment "si-3-pornic"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid13 address1 "Pornic"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid13 building "12, chemin des trois croix"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid13 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid13 217.15.80.222
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid13 217.15.80.222  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid13 217.15.80.222  descr "si-3-pornic"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid13 217.15.80.222  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid13 217.15.80.222  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.222 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid14 "mx-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid14 comment "mx-1-cbv1"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid14 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid14 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid14 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid14 217.15.80.12
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid14 217.15.80.12  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid14 217.15.80.12  descr "mx-1-cbv1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid14 217.15.80.12  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid14 217.15.80.12  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.80.12 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid15 "mx-1-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid15 comment "mx-1-cbv2"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid15 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid15 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid15 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid15 217.15.88.12
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid15 217.15.88.12  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid15 217.15.88.12  descr "mx-1-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid15 217.15.88.12  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid15 217.15.88.12  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   217.15.88.12 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid16 "mail-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid16 comment "mail-1-cbv1"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid16 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid16 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid16 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid16 169.254.0.164
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid16 169.254.0.164  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid16 169.254.0.164  descr "mail-1-cbv1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid16 169.254.0.164  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid16 169.254.0.164  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   169.254.0.164 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid17 "mail-1-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid17 comment "mail-1-cbv2"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid17 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid17 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid17 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid17 169.254.1.164
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid17 169.254.1.164  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid17 169.254.1.164  descr "mail-1-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid17 169.254.1.164  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid17 169.254.1.164  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   169.254.1.164 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid18 "av-1-cbv1" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid18 comment "av-1-cbv1"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid18 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid18 building "Courbevoie Salle-1"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid18 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid18 169.254.0.165
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid18 169.254.0.165  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid18 169.254.0.165  descr "av-1-cbv1"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid18 169.254.0.165  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid18 169.254.0.165  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   169.254.0.165 78Ggruzg4p timeout=5000 version=v2c retries=3

/usr/share/opennms/bin/provision.pl  node       add   Alphalink foreignid19 "av-1-cbv2" 
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid19 comment "av-1-cbv2"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid19 address1 "Paris"
/usr/share/opennms/bin/provision.pl  asset      add   Alphalink foreignid19 building "Courbevoie Salle-2"
/usr/share/opennms/bin/provision.pl  category   add   Alphalink foreignid19 "Server"
/usr/share/opennms/bin/provision.pl  interface  add   Alphalink foreignid19 169.254.1.165
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid19 169.254.1.165  snmp-primary P
/usr/share/opennms/bin/provision.pl  interface  set   Alphalink foreignid19 169.254.1.165  descr "av-1-cbv2"
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid19 169.254.1.165  ICMP 
/usr/share/opennms/bin/provision.pl  service    add   Alphalink foreignid19 169.254.1.165  SNMP 
/usr/share/opennms/bin/provision.pl  snmp       set   169.254.1.165 78Ggruzg4p timeout=5000 version=v2c retries=3

#import group to database 
/usr/share/opennms/bin/provision.pl requisition import Alphalink
