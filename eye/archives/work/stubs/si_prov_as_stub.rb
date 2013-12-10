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

data = { 'account_code' => '0990000001007',
  'subscriber_number' => '33123456007',
  'max_inbound_calls' => 100,
  'max_outbound_calls' => 100,
  'max_calls' => 100,
  'inbound_numbering_plan' => 'e164',
  'outbound_numbering_plan' => 'e164',
  'locked' => '0',
  'carrier_code' => 'D200911200001.1',
  'trunk' => '1',
  'fixed_cid' => '0',
  'indication' => 0
} 

msg = [{ 'data' => data,
  'uri' => "/voip/as/voip_account/0990000001007",
  'action' => 'update'
}]
msg = msg.to_json
headers = {"reply-to" => prov_response, "node_name" => "scscf-2-maquette-as", "expires" => (Time.now.to_i + 10) * 1000, "correlation-id" => ["scscf-2-maquette", msg, Time.now].hash }

connection.publish prov_queue, msg, headers

puts connection.receive.body

connection.disconnect

