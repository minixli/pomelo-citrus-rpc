# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require 'citrus-rpc/rpc-server/acceptors/ws_acceptor'
require 'citrus-rpc/rpc-server/dispatcher'

module CitrusRpc
  # RpcServer
  #
  #
  module RpcServer
    # Gateway
    #
    #
    class Gateway
      include Dispatcher
      include Utils::EventEmitter

      # Create a gateway
      #
      # @param [Hash] args Options
      #
      # @option args [Integer] port
      # @option args [Class]   acceptor_class
      # @option args [Hash]    services
      def initialize args={}
        @port = args[:port] || 3050
        @started = false
        @stoped = false

        @acceptor_class = args[:acceptor_class] || WsAcceptor
        @services = args[:services]

        @acceptor = @acceptor_class.new(args) { |msg, &block|
          dispatch msg, @services, &block
        }
      end

      # Start the gateway
      def start
        raise RuntimeError 'gateway already started' if @started
        @started = true

        @acceptor.on(:error) { |*args| emit :error, *args }
        @acceptor.on(:closed) { |*args| emit :closed, *args }
        @acceptor.listen @port
      end

      # Stop the gateway
      def stop
        return unless @started && !@stoped
        @stoped = true
        @acceptor.close
      end
    end
  end
end
