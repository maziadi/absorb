#!/usr/bin/env ruby

require 'rubygems'
require 'stomp'
require 'pp'

conn = Stomp::Connection.new('as', 'hNRfIOgHvF', '10.44.81.253', 61613, false)

conn.subscribe("/queue/sigal.db.query", :ack => 'auto')

loop do
  msg = conn.receive
  pp msg.headers
  timestamp = msg.headers["timestamp"].to_i
  expires = msg.headers["expires"].to_i
  puts "expires is in #{(expires - timestamp)/1000}s"
end
