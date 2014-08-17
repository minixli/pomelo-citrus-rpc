# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 4 July 2014

require 'citrus-rpc/rpc-server/gateway'

module CitrusRpc
  # RpcServer
  #
  #
  module RpcServer
    # Server
    #
    # @example
    #
    # Specifiy remote service interface paths
    #
    #  dirname = File.expand_path File.dirname(__FILE__)
    #  records = [
    #    { :namespace => 'user', :path => dirname + '/remote/test' }
    #  ]
    #
    # Create a new rpc server and start it
    #
    #  Server.new(:records => records, :port => 3333).start
    #
    class Server
      include CitrusLoader
      include Utils::EventEmitter

      # Create a new rpc server
      #
      # @param [Hash] args Options
      #
      # @option args [Integer] port
      # @option args [Array]   records
      def initialize args={}
        raise ArgumentError, 'server port empty' unless args[:port]
        raise ArgumentError, 'server port must be bigger than zero' unless args[:port] > 0
        raise ArgumentError, 'records empty' unless args[:records]
        raise ArgumentError, 'records must be an array' unless args[:records].respond_to? :to_a

        @services = {}

        create_namespace args[:records]
        load_remote_services args[:records], args[:context]

        args[:services] = @services

        @gateway = Gateway.new args
        @gateway.on(:error) { |*args| emit :error, *args }
        @gateway.on(:closed) { |*args| emit :closed, *args }
      end

      # Start the rpc server
      def start
        @gateway.start
      end

      # Stop the rpc server
      def stop
        @gateway.stop
      end

      private

      # Create remote services namespace
      #
      # @param [Array] records
      #
      # @private
      def create_namespace records
        records.each { |record| @services[record[:namespace]] ||= {} }
      end

      # Load remote services
      #
      # @param [Array]  records
      # @param [Object] context
      #
      # @private
      def load_remote_services records, context
        records.each { |record|
          remotes = load_app_remote record[:path]
          remotes.each { |service, remote|
            @services[record[:namespace]][service] = remote.new context
          }
        }
      end
    end
  end
end
