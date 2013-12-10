require 'rubygems'
require 'bundler'

Bundler.setup

require 'stomp'
require 'json'
require 'time'

uri = "stomp://erp:TV74iG9dCC@voip-activemq-maquette:61613"
prov_queue = "/queue/provisioning"
prov_response = "/temp-queue/provisioning"

login, passcode, host, port = uri.scan(/^stomp:\/\/([\w\.]+):([\w\d]+)@([\d\w\.-]+):(\d+)$/).first
port = port.to_i

connection = Stomp::Connection.new login, passcode, host, port, false
connection.subscribe(prov_response, :ack => "auto")

data = { 'account_code' => '0980000001002',
  'msisdn' => '33123456782',
  'carrier_code' => 'D200911200002.2'
} 

msg = [{ 'data' => data,
  'uri' => "/voip/as/mobile_account/0980000001002",
  'action' => 'update'
}]
msg = msg.to_json
headers = {"reply-to" => prov_response, "node_name" => "scscf-2-maquette-as", "expires" => (Time.now.to_i + 10) * 1000, "correlation-id" => ["scscf-2-maquette", msg, Time.now].hash }

connection.publish prov_queue, msg, headers

puts connection.receive.body

connection.disconnect

