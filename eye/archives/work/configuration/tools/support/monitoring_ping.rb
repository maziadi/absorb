#!/usr/bin/env ruby

require 'net/ssh'

if RUBY_VERSION.eql?("1.8.7")
  require 'tools/model'
else
  require_relative '../model'
end

class MonitorEditor 
  def do_ping(interface,ip,file)
    ping = $equipment.exec!("ping -s 1472 #{ip} -I #{interface} -c 900")
    create_file(ping,file)
  end
  def create_file(data,file)
    myFile = File.open(file, "a+")
    myFile.write data
    myFile.close
  end
  def monitor_ping(equipment,ip,interface,nb_seq)
    print "Le monitoring est lance. Il va durer #{nb_seq} fois 15min.\n"
    $equipment=Net::SSH.start(equipment,'root')
    date = Date.today
    file = "/tmp/monitoring_ping_#{date.year}_#{date.month}_#{date.day}_#{equipment}_#{interface}_#{ip}.log"
    cpt = 1
    nb_seq.to_i.times do
      do_ping(interface,ip,file)
      print "Sequence #{cpt} terminee\n"
      cpt = cpt + 1
    end
    $equipment.close
    print "Le fichier de monitoring se trouve dans ton /tmp/ping.log\n"
  end
end
