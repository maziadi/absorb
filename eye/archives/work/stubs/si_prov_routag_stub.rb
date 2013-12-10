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

data = {
  'group_id' => '3',
  'updated_at' =>  "1970-01-01T01:00:00+01:00",
  'destinations' => [ {
      'weight' => "1",
      'destination' => 'voicemail-1-maquette.sip.openvno.net:5060',
    },
  ]
} 

msg = [{ 'data' => data,
  'uri' => "/voip/routag/media_group/3",
  'action' => 'update'
}]
msg = msg.to_json
headers = {"reply-to" => prov_response, "node_name" => "scscf-2-maquette-routag", "expires" => (Time.now.to_i + 10) * 1000, "correlation-id" => ["scscf-2-maquette-routag", msg, Time.now].hash }

connection.publish prov_queue, msg, headers

puts connection.receive.body

connection.disconnect

