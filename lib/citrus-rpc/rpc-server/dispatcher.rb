# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

module CitrusRpc
  # RpcServer
  #
  #
  module RpcServer
    # Dispatcher
    #
    #
    module Dispatcher
      # Dispatch message to appropriate service object
      #
      # @param [Hash] msg
      # @param [Hash] services
      def dispatch msg, services, &block
        unless namespace = services[msg['namespace']]
          block.call Exception.new 'no such namespace: ' + msg['namespace']
          return
        end
        unless service = namespace[msg['service']]
          block.call Exception.new 'no such service: ' + msg['service']
          return
        end
        unless service.respond_to? msg['method']
          block.call Exception.new 'no such method: ' + msg['method']
          return
        end

        service.send msg['method'], *msg['args'], &block
      end
    end
  end
end
