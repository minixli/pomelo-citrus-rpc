# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 4 July 2014

module CitrusRpc
  # RpcClient
  #
  #
  module RpcClient
    # Proxy
    #
    #
    module Proxy
      private

      # Create proxy
      #
      # @param [Hash] args Options
      #
      # @option args [Class] remote
      # @option args [Hash]  attach
      # @option args [#call] proxy_cb
      #
      # @private
      def create_proxy args={}
        res = Object.new
        methods = args[:remote].instance_methods
        methods.each { |method|
          res.define_singleton_method method, proc{ |*inner_args, &block|
            args[:proxy_cb].call args[:service], method, args[:attach], false, *inner_args, &block
          }
        }
        res
      end
    end
  end
end
