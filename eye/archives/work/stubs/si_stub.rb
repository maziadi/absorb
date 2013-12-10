require 'rubygems'
require 'bundler'

Bundler.setup

require 'stomp'
require 'json'
require 'time'

DATA = {
  "33123456001" => { :msisdn => "33123456001", :rio => "asEfgh", :date => Time.parse("13-06-2016").iso8601},
  "33123456002" => { :msisdn => "33123456002", :rio => "asPf+gh", :date => Time.parse("13-06-2016").iso8601},
  "33123456003" => { :msisdn => "33123456003", :rio => nil, :date => nil },
  "33123456004" => { :msisdn => "33123456004", :rio => nil, :date => Time.parse("2013-03-11").iso8601 },
  "33123456005" => { :msisdn => "33123456005", :rio => "asPf+gh", :date => nil },
  "33123456006" => { :msisdn => nil, :rio => nil, :date => nil },
  "33123456007" => { :msisdn => "33123456007", :rio => "qwPrty", :date => Time.parse("11-09-2016").iso8601 }
}
#conn = Stomp::Connection.new 'erp', 'TV74iG9dCC', '10.44.81.249', 61613
conn = Stomp::Connection.new 'si', 'pE6TJUOgCK', '10.44.81.253', 61613
conn.subscribe("/queue/hermes", { :ack => 'auto', :selector => "messageType = 'SVI.RIO.QUERY.REQUEST'" })

headers = {
  "node_name" => "pcscf-3-maquette",
  "messageType" => "SVI.RIO.QUERY.RESPONSE",
}

Svirio =  { :msisdn => nil, :rio => nil, :date => nil }

loop do
  res = conn.receive
  reply_to = res.headers["reply-to"]
  headers["JMSCorrelationID"] = res.headers["correlation-id"]
  body = JSON.parse(res.body)
  
  if(data = DATA[body["msisdn"]]) 
    puts data.inspect
    conn.publish(reply_to, data.to_json, headers)
  else
    puts "unknown number: #{res.inspect}"
    conn.publish(reply_to, Svirio.merge(:msisdn => body["msisdn"]).to_json, headers)
  end
end

# prov_response = "/temp-topic/si.svirio"
# prov_queue    = "/queue/si.svirio"
# running = true
# connection = OnStomp.connect('stomp://as:hNRfIOgHvF@10.44.81.249:61613')
# puts 'tutu'
# @sub = connection.subscribe(prov_response, :ack => 'auto') do |m|
