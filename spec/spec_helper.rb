# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../lib/citrus-rpc', __FILE__)

Client      = CitrusRpc::RpcClient::Client
MailStation = CitrusRpc::RpcClient::MailStation
WsMailBox   = CitrusRpc::RpcClient::WsMailBox
Proxy       = CitrusRpc::RpcClient::Proxy
Router      = CitrusRpc::RpcClient::Router

Server      = CitrusRpc::RpcServer::Server
Gateway     = CitrusRpc::RpcServer::Gateway
Dispatcher  = CitrusRpc::RpcServer::Dispatcher
WsAcceptor  = CitrusRpc::RpcServer::WsAcceptor

RSpec.configure { |config|
  config.mock_with(:rspec) { |c|
    c.syntax = [:should, :expect]
  }
  config.expect_with(:rspec) { |c|
    c.syntax = [:should, :expect]
  }
}
