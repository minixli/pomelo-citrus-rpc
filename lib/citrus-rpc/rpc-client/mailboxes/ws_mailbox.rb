# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 7 July 2014

require 'websocket-eventmachine-client'
require 'citrus-rpc/util/constants'

module CitrusRpc
  # RpcClient
  #
  #
  module RpcClient
    # WsMailBox
    #
    #
    class WsMailBox
      include Utils::EventEmitter

      # Create a new websocket mailbox
      #
      # @param [Hash] server server info
      # @param [Hash] args   Options
      #
      # @option args [Object] context
      # @option args [Object] route_context
      # @option args [#call]  router
      # @option args [String] router_type
      def initialize server, args={}
        @cur_id = 0

        @id = server[:id]
        @host = server[:host]
        @port = server[:port]

        @requests = {}
        @timeout = {}
        @queue = []

        @buffer_msg = args[:buffer_msg]
        @interval = args[:interval] || Constants::DefaultParams::Interval
        @timeout_value = args[:timeout] || Constants::DefaultParams::Timeout

        @connected = false
        @closed = false

        @args = args
      end

      # Connect to remote server
      def connect
        if @connected
          block_given? and yield Exception.new 'mailbox has already connected'
          return
        end

        begin
          @ws = WebSocket::EventMachine::Client.connect :uri => 'ws://' + @host + ':' + @port.to_s
          @ws.onopen {
            return if @connected
            @connected = true
            @timer = EM.add_periodic_timer(@interval) { flush } if @buffer_msg
            block_given? and yield
          }

          @ws.onmessage { |msg, type|
            process_msg msg, type
          }

          @ws.onerror { |err| }
          @ws.onclose { |code, reason|
            emit :close, @id
          }
        rescue => err
          block_given? and yield err
        end
      end

      # Close the mail box
      def close
        return if @closed
        @closed = true
        @ws.close
      end

      # Send message to remote server
      #
      # @param [Hash]  msg
      # @param [Hash]  opts
      # @param [#call] block
      def send msg, opts, block
        unless @connected
          block.call Exception.new 'websocket mailbox has not connected'
          return
        end

        if @closed
          block.call Exception.new 'websocket mailbox has already closed'
          return
        end

        id = @cur_id
        @cur_id += 1
        @requests[id] = block

        pkg = { :id => id, :msg => msg }
        if @buffer_msg
          enqueue pkg
        else
          @ws.send pkg.to_json
        end
      end

      private

      # Enqueue the package
      #
      # @param [Hash] pkg
      #
      # @private
      def enqueue pkg
        @queue << pkg
      end

      # Flush
      #
      # @private
      def flush
        if @closed || @queue.length == 0
          return
        end
        @ws.send @queue.to_json
        @queue = []
      end

      # Process message
      #
      # @param [Hash] msg
      #
      # @private
      def process_msg msg, type
        begin
          pkg = JSON.parse msg
          pkg_id = pkg['id']
          pkg_resp = pkg['resp']

          return unless block = @requests[pkg_id]
          @requests.delete pkg_id

          args = [nil]
          pkg_resp.each { |arg| args << arg }

          block.call *args
        rescue => err
        end
      end

      # Batch version for process_msg
      #
      # @private
      def process_msgs
      end
    end
  end
end
