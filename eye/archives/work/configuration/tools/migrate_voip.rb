#!/usr/bin/env ruby
require 'yaml'

def head(title)
  puts "=" * 80
  puts "= #{title}"
  puts "=" * 80
  yield 
  puts
end

accounts_hash = YAML::load(File::open('data/voip_accounts.yaml'))
numbers_hash = YAML::load(File::open('data/voip.yaml'))

accounts = accounts_hash.select do |k, v|
  k =~ /^(0990000047001|0990000056001)/ && !v[:destination].nil?
end.sort_by do |k, v| k
end.map do |ref, account_hash|
  number_hashs = numbers_hash.select { |k, v| v[:account_code] == ref }.map { |k, v| v }
  account_hash[:numbers] = number_hashs
  account_hash
end

head "Summary" do
  accounts.each do |account|
    puts "== #{account[:ref]}[#{account[:numbers].size}]"
  end
end


head "Routing" do
  accounts.each do |account|
    puts "# #{account[:ref]} - #{account[:numbers].first[:client]}"
    account[:numbers].each do |number|
      puts "route \"\#{prefix}#{number[:number].slice(2..-1)}\", $failovervnoc5"
    end
  end
end

head "PCSCF 1 - cmd line" do
  accounts.each do |account|
    puts "opensipsctl add #{account[:ref]} #{account[:password]}"
  end
end

head "PCSCF 1 - DB" do
puts "use opensips"
  accounts.each do |account|
    puts "UPDATE subscriber SET carrier=1 where username='#{account[:ref]}'; "
  end
end

head "PCSCF 2 - cmd line" do
  puts "rubyrep sync -c /etc/rubyrep/rubyrep-synch-pcscf-config.conf"
end

head "AS - DB (deux fois)" do
  accounts.each do |account|
    number = account[:numbers].first
    max = account[:max]
    plans = account[:profile].split(':').map {|a| "'#{a}'" }.join(", ")
    insee_code = account[:insee_code] || number[:insee_code]
    insee_code ||= "99999"
    puts """replace into line_information 
      (account_code,subscriber_number,max_inbound_calls,max_outbound_calls,max_calls,
       outbound_numbering_plan,inbound_numbering_plan,locked,carrier_code,
       trunk,fixed_cid,indication,creation_date) values 
      ('#{account[:ref]}', '#{number[:number]}', #{max}, #{max}, #{max}, #{plans}, 0, 'D200911200001.1', 1, 0, 1, now());"""
    account[:numbers].each do |number|
      puts """replace into number (creation_date, number, subscriber_number, insee_code, fax) values 
        (now(), '#{number[:number]}', '#{account[:subscriber_number]}', '#{insee_code}', 0);"""
    end
    puts
  end
end
