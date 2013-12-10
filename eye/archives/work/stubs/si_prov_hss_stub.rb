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

data = { 'account_code' => '0990000999004',
            'updated_at' => "1970-01-01T01:00:00+01:00",
            'domain' => 'sip.openvno.net',
            'username' => '0990000999004',
            'group_id' => 1,
            'endpoints' =>
            [{ 'failure' => "0",
              'port' => 5060,
              'weight' => "1.0",
              'ip' => '217.15.80.163'
            }]
        }
 
msg = [{ 'data' => data,
  'uri' => "/voip/hss/interconnection/d200911200001/0990000999004",
  'action' => 'update'
}]
msg = msg.to_json
headers = {"reply-to" => prov_response, "node_name" => "pcscf-3-maquette", "expires" => (Time.now.to_i + 10) * 1000, "correlation-id" => ["pcscf-3-maquette", msg, Time.now].hash }

connection.publish prov_queue, msg, headers

puts connection.receive.body

connection.disconnect

