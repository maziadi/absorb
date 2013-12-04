#!/usr/bin/env ruby

require 'erb'

if ARGV.length != 1 
  puts "Usage: gen_email.rb <fichier(login, email, mdp)>"
  exit -1
end

records = File::open(ARGV[0], "r") { |f| 
	f.readlines 
}.collect { |line|
	line.chomp.split(/ /)
}

ldif_template = ERB.new <<-EOF 
dn: uid=<%= user %>,ou=users,ou=alphalink,dc=init-sys,dc=com
mailHost: srv-mail.alphalink.fr
vacationActive: FALSE
homeDirectory: <%= homeDirectory %> 
uid: <%= user %>
mail: <%= mail %> 
objectClass: ldapminUser
objectClass: simplePerson
objectClass: mailUser
objectClass: amavisAccount
objectClass: Vacation
userPassword: <%= password %>
EOF

"""
dn: uid=ma917-40@villtarn.fr.fto,ou=users,ou=alphalink,dc=init-sys,dc=com
mailHost: srv-mail.alphalink.fr
vacationActive: FALSE
homeDirectory: m/a/9/ma917-40@villtarn.fr.fto
uid: ma917-40@villtarn.fr.fto
mail: cferreira@ville-tarnos.fr
objectClass: ldapminUser
objectClass: simplePerson
objectClass: mailUser
objectClass: amavisAccount
objectClass: Vacation
"""

puts records.collect { |record|
	user, mail, password = record
	homeDirectory = user.gsub(/\./,'').gsub(/^(.)(.)(.).*$/, '\1/\2/\3/') + user
	ldif_template.result(binding)
}.join("\n")

