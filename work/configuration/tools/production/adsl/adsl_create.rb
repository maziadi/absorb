#!/usr/bin/env ruby
# coding: utf-8

# Ce simple script affiche les block et les commandes pour provisionning d'un ADSL simple (IP publique)
# Il ne fait aucun modification sur backbone


require 'date'
#require 'colorize'

charset = %w{0 1 2 3 4 6 7 9 A C D E F G H J K M N P Q R T V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z}

print "Commande numero : "
commande = STDIN.gets.strip

print "Client : "
client = STDIN.gets.strip.upcase 

print "Societe : "
client2 = STDIN.gets.strip.upcase

print "Ville : "
ville = STDIN.gets.strip.upcase 

print "ADSL debit: "
adsl_debit = STDIN.gets.strip 

print "NDI : "
ndi = STDIN.gets.strip 

print "ADSL Login: "
login = STDIN.gets.strip 

print "ADSL IP: "
ip = STDIN.gets.strip  

passw = (0...8).map{ charset.to_a[rand(charset.size)] }.join

date = DateTime.now.strftime('%d/%m/%Y')
prefix, suffix = login.split("@")

print "\n"

print <<RADIUS
# #{client} :: #{client2} - #{ville} :: #{adsl_debit} :: #{ndi} :: #{date} :: @#{suffix}
#{prefix} Auth-Type := Local, User-Password := #{passw}
\tFramed-IP-Address = #{ip},
Fall-Through = No

RADIUS

print "____________\n"
puts "vispprov adsl add -l #{login} -p #{passw} -a #{ip} -c \"#{client} :: #{client2} - #{ville} :: #{adsl_debit} :: #{ndi} :: #{date} :: @#{suffix}\""
print "____________\n"
puts "rake test_adsl[#{login},#{passw}]"
print "_________ MAIL ________\n"
print <<MAIL
Bonjour,

Je vous informe de la mise à disposition du lien ADSL suivant :
#{client} - #{client2} - #{ville}  (n°affaire: #{commande})

ADSL #{adsl_debit} : Livrée sur le NDI: #{ndi}
Configuration ADSL:
   Login: #{login}
   MotDePasse: #{passw}
   @IP: #{ip}

Cordialement,

MAIL
