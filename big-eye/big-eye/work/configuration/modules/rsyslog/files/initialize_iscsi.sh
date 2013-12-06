#!/bin/bash
#
# Script d'initialisation des targets iscsi

discover_iscsi () {
  SAN="san-1-cbv1"
  iscsiadm -m discovery -t st -p $SAN 2>&1 > /dev/null

  # Nettoyage des fichiers inutiles
  find /etc/iscsi/ -name 'iqn*'  ! -iname "*$(hostname)*" -exec rm -rf {} \; 2>&1 > /dev/null
}

configure_iscsi () {
  # passage en auto du montage de la target
  file=$(find /etc/iscsi/nodes/ -type f)
  sed -i 's/manual/automatic/' $file
  directory="$(hostname)_archives"
  device="iscsi_$directory"
  if ! grep -r $device /etc/fstab; then
    echo "/dev/$device  /var/log/old/ xfs _netdev 0 0" >> /etc/fstab
  fi
  /etc/init.d/open-iscsi restart
}

discover_iscsi
configure_iscsi
