require 'rubygems'
require 'bundler'

Bundler.setup

require 'stomp'
require 'json'
require 'time'

$KCODE = 'UTF8'

#conn = Stomp::Connection.new 'erp', 'TV74iG9dCC', '10.44.81.249', 61613
conn = Stomp::Connection.new 'si', 'pE6TJUOgCK', '10.44.81.253', 61613
conn.subscribe("/queue/hermes", { :ack => 'auto', :selector => "messageType = 'SMS.SEND.REQUEST'" })

headers = {
  "node_name" => "pcscf-3-maquette",
  "messageType" => "SMS.SERVER.ACK",
}

Ack = {:status => nil, :message =>nil}
loop do
  res = conn.receive
  reply_to = res.headers["reply-to"]
  headers["JMSCorrelationID"] = res.headers["correlation-id"]
  body = JSON.parse(res.body)
  
  puts "Ack envoye \n #{res.inspect}"
  conn.publish(reply_to, Ack.merge(:status => 200, :message => "OK").to_json, headers)

end

