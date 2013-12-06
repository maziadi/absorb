#!/bin/sh

# Generation dun fichier servant a la generation de la partie incoming sur bc pour le centrex-1-cbv1

echo -en "\n\n;\n; CENTREX-1-CBV1\n;\n\n" > data/centrex-1-cbv1.exten
for acc in `tools/voip.rb search -e 'destination == "centrex-1-cbv1"' -c account_code | cut -d ' ' -f 2 | sort -u`
  do  echo -en "\n;  $acc\n" >> data/centrex-1-cbv1.exten
  for did in `tools/voip.rb search -e "account_code == '$acc' && destination == 'centrex-1-cbv1'" -c | cut -d : -f 1`
    do  echo -en "exten => _$did,1,Proc(did-national,0990000001007,100)\n" >> data/centrex-1-cbv1.exten
  done 
done


## Generation dun fichier servant a la generation de la partie incoming sur bc pour le registrar-1-cbv2
#
#echo -en "\n\n;\n; registrar-1-cbv2\n;\n\n" > data/registrar-1-cbv2.exten
#for acc in `tools/voip.rb search -e 'destination == "registrar-1-cbv2"' -c account_code | cut -d ' ' -f 2 | sort -u`
#  do  echo -en "\n;  $acc\n" >> data/registrar-1-cbv2.exten
#  for did in `tools/voip.rb search -e "account_code == '$acc' && destination == 'registrar-1-cbv2'" -c | cut -d : -f 1`
#    do  echo -en "exten => _$did,1,Proc(did-national,0990000001008,100)\n" >> data/registrar-1-cbv2.exten
#  done 
#done
#
#
## Generation (stdout) des entrees concernant centrex-1-cbv1 pour le script de config de gw-voip-2-cbv2
#
#echo -en "\n#\n# CENTREX-1-CBV1\n#\n"
#for acc in `tools/voip.rb search -e 'destination == "centrex-1-cbv1"' -c account_code | cut -d ' ' -f 2 | sort -u`
#  do  echo -en "# $acc\n"
#  for did in `tools/voip.rb search -e "account_code == '$acc' && destination == 'centrex-1-cbv1'" -c | cut -d : -f 1`
#    do  echo -en "route '$did', :bc_voip_1_cbv2\n"
#  done 
#done
#
#
## Generation (stdout) des entrees concernant registrar-1-cbv2 pour le script de config de gw-voip-2-cbv2
#
#echo -en "\n#\n# REGISTRAR-1-CBV2\n#\n"
#for acc in `tools/voip.rb search -e 'destination == "registrar-1-cbv2"' -c account_code | cut -d ' ' -f 2 | sort -u`
#  do  echo -en "# $acc\n"
#  for did in `tools/voip.rb search -e "account_code == '$acc' && destination == 'registrar-1-cbv2'" -c | cut -d : -f 1`
#    do  echo -en "route '$did', :bc_voip_1_cbv2\n"
#  done 
#done
#
#
## Generation (stdout) des entrees pour gw-voip-2-cbv2 selon account_code
#
#acc=???
#echo "$acc - ";for did in `tools/voip.rb search -e "account_code == '$acc'" -c | cut -d : -f 1`; do echo "route \"#{prefix}${did/33/}\", :bc_voip_1_cbv2"; done
#
#
## Modification de la destination dans suivi voip (pour vrais comptes clients)
#
#acc=???
#tools/voip.rb exec -e "account_code == '$acc'" -c -d "did.destination = 'bc-voip-1-cbv2'; did.validation = 'AM/`date +%Y-%m-%d`'"
#
#
## Generation (stdout) des commandes mysql pour gw-voip-1-cbv1 (mysql sur log-1-cbv2)
#
#acc=???
#for did in `tools/voip.rb search -e "account_code == '$acc'" -c | cut -d : -f 1 | sed s/33/0/`; do echo "insert into lcr select '$did', '%', 1, 0; insert into lcr select '%#$did', '%', 141, 0;"; done
#
#
## Generation (stdout) des commandes mysql pour gw-voip-2-cbvX (mysql de SCP) : insertion tranche de num
#acc=???
#num=3397075461
#subn=33253441910
#for i in `tools/voip.rb search $num -e "account_code == '$acc'" -c | cut -d : -f 1`; do echo "insert into number (number, subscriber_number, insee_code) values ('$i', '$subn', '`tools/voip.rb search $i -e "account_code == '$acc'" -c insee_code | cut -d \  -f 2`');"; done
#
#
## Generation (stdout) des commandes mysql pour srv-spare-cbv1 (mysql de AS) : insertion tranche de num
#acc=???
#num=3397075461
#subn=33253441910
#for i in `tools/voip.rb search $num -e "account_code == '$acc'" -c | cut -d : -f 1`; do echo "insert into number (creation_date, number, subscriber_number, insee_code, fax) values (now(), '$i', '$subn', '`tools/voip.rb search $i -e "account_code == '$acc'" -c insee_code | cut -d \  -f 2`', 0);"; done
#
#
## Generation (stdout) des commandes mysql pour mysql de SCP : update code_insee
#num=???
#acc=???
#for i in `tools/voip.rb search $num -e "account_code == '$acc'" -c | cut -d : -f 1`; do echo "update number set insee_code='`tools/voip.rb search $i -e "account_code == '$acc'" -c insee_code | cut -d \  -f 2`' where number='$i';"; done
