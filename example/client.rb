# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../lib/citrus-rpc', __FILE__)

Client = CitrusRpc::RpcClient::Client

dirname = File.expand_path File.dirname(__FILE__)
record = {
  :namespace => 'user',
  :server_type => 'test',
  :path => dirname + '/remote/test'
}

servers = [
  { :id => 'test-server-1', :server_type => 'test', :host => '127.0.0.1', :port => 3333 }
]

context = { :server_id => 'test-server-1' }

route_context = servers

router = proc{ |route_param, msg, route_context, &block|
  block.call nil, route_context[0][:id] if block
}

client = Client.new :context => context, :route_context => route_context, :router => router

client.add_proxy record
client.add_servers servers

EM.run do
  client.start do |err|
    puts 'rpc client started'

    route_param = nil
    client.proxies.user.test.serviceRemote.echo(route_param, 'hello') do |err, resp|
      puts err if err
      puts resp
    end
  end
end
