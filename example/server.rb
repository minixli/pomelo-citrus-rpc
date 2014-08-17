# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../lib/citrus-rpc', __FILE__)

Server = CitrusRpc::RpcServer::Server

dirname = File.expand_path File.dirname(__FILE__)
records = [
  { :namespace => 'user', :path => dirname + '/remote/test' }
]
port = 3333

server = Server.new :records => records, :port => port

EM.run do
  server.start
  puts 'rpc server started'
end
