#!/bin/sh

list="mail-2-cbv2 zimbra-1-yago"

for host in $list
  do
  account_nb=$(ssh $host 'spam=`su - zimbra -c "zmprov getConfig zimbraSpamIsSpamAccount" | cut -d " " -f 2`
ham=`su - zimbra -c "zmprov getConfig zimbraSpamIsNotSpamAccount" | cut -d " " -f 2`
wiki=`su - zimbra -c "zmprov getConfig zimbraNotebookAccount" | cut -d " " -f 2`
su - zimbra -c "zmprov getAllAccounts"  | grep -v "^${spam}\|${ham}\|${wiki}$" | wc -l')
  ip=`tools/infra.rb search $host -c public_addr | cut -d " " -f 2`
  [ -z "$ip" ] && ip=`tools/infra.rb search $host -c admin_addr | cut -d " " -f 2`
  echo "$host ($ip) $account_nb"
done


