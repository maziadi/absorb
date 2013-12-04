#!/usr/bin/env ruby

require 'net/ssh'
if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative 'model'
end

def do_search(hostname)
     Model::load().find_hosts(hostname, :ancestor => 'visp').collect { |node| node.name }
end

def verificationFormatIP
  STDERR.print "Le format de l'ip n'est pas bon \n"
  exit(1)
end

def get_visp_name(vlan)
  vispName = $bgp1.exec!("cat /etc/network/interfaces | grep #{vlan} -B 1 | grep '^# [A-Z\-]'")
  return vispName[(vispName=~/\s/)+1,vispName.length].downcase.chomp
end

## recuperation de l'interface concernée par le SPAM
def getInterfaceVispName(ip)
  interface = $1 if $visp.exec!("ip route get #{ip}") =~ /dev\s*([^\s]*)/
    case interface[0,3]
    when "nas" :
      return interface 
    when "ppp" :
      getClientAdslName(ip)
    when "ix0" :
      return "-"
    when "bon"
      return "0"
    else
      getClientAdslName(ip)
  end
end

def getClientAdslName(ip)
  return $1 if $visp.exec!("cat /etc/raddb/users | grep #{ip} -B 1 | grep \"Auth-Type\"")=~/^([^\s]*)/
end

## vérification du format du parametre
verificationFormatIP if ARGV.size != 1 

ip=ARGV[0]

## On ouvre une session ssh sur les deux BGP
$bgp1=Net::SSH.start('bgp-1-cbv1','root')
$bgp2=Net::SSH.start('bgp-1-cbv2','root')

vlanTransitBgp1=$1 if $bgp1.exec!("ip route get #{ip}") =~ /(eth0.\d{1,4})/
vlanTransitBgp2=$1 if $bgp2.exec!("ip route get #{ip}") =~ /(eth0.\d{1,4})/

## on verifie que le vlan est bien identique sur les deux bgp sinon cas spécifique
if vlanTransitBgp1==vlanTransitBgp2
  ## vlans OK, on poursuit
  vispName=get_visp_name(vlanTransitBgp1)
  ## on va dans le fichier infrastructure.yaml pour prendre le vrai nom de visp - permet de matcher plusieurs visp d'un meme client 
  tableauVispName = do_search(vispName)
  clientName="0"
  for t in tableauVispName 
    $visp=Net::SSH.start(t,'root')
    if clientName == "0" 
      clientName=getInterfaceVispName(ip)
      vispName=t
    end
    $visp.close
  end
  if clientName == "0"
    print "IP non trouvee - A traiter à la main \n"
  else
    if clientName == "-"
      print "SPAM emis depuis le VISP #{vispName} - Client sur table isolee\n"
    else
      print "SPAM emis depuis le client #{clientName} du #{vispName}\n"
    end
  end
else
  print "IP non trouvee - A traiter à la main \n"
end

$bgp1.close
$bgp2.close
