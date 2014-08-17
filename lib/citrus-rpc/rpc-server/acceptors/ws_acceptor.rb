# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require 'websocket-eventmachine-server'

module CitrusRpc
  # RpcServer
  #
  #
  module RpcServer
    # WsAcceptor
    #
    #
    class WsAcceptor
      include Utils::EventEmitter

      # Create a new websocket acceptor
      #
      # @param [Hash] args Options
      #
      # @option args [Boolean] buffer_msg
      # @option args [Integer] interval
      def initialize args={}, &block
        @buffer_msg = args[:buffer_msg]
        @interval = args[:interval]

        @server = nil
        @wss = {}

        @msg_queues = {}
        @callback = block

        @listening = false
        @closed = false
      end

      # Listen on port
      #
      # @param [Integer] port
      def listen port
        raise RuntimeError 'acceptor double listen' if @listening

        begin
          @server = WebSocket::EventMachine::Server.start(:host => '0.0.0.0', :port => port) { |ws|
            ws.onopen {
              @wss[ws.signature] = ws
              peer_port, peer_host = Socket.unpack_sockaddr_in ws.get_peername
              emit :connection, { :id => ws.signature, :ip => peer_host }
            }

            ws.onmessage { |msg, type|
              begin
                pkg = JSON.parse msg
                if pkg.instance_of? Array
                  process_msgs ws, pkg
                else
                  process_msg ws, pkg
                end
              rescue => err
              end
            }

            ws.onclose {
              @wss.delete ws.signature
              @msg_queues.delete ws.signature
            }
            ws.onerror { |err| emit :error, err }
          }
        rescue => err
          emit :error, err
        end

        on(:connection) { |obj| ip_filter obj }
        @listening = true
      end

      # Close the acceptor
      def close
        return unless @listening && !@closed
        EM.stop_server @server
        @closed = true
        emit :closed
      end

      private

      # Clone error
      #
      # @private
      def clone_error origin
        { 'msg' => origin.message, 'stack' => nil }
      end

      # Process message
      #
      # @param [Object] ws
      # @param [Hash]   pkg
      #
      # @private
      def process_msg ws, pkg
        @callback.call pkg['msg'] { |*args|
          args.each_with_index { |arg, index|
            args[index] = clone_error arg if arg.is_a? Exception
          }

          resp = { 'id' => pkg['id'], 'resp' => args }
          if @buffer_msg
            enqueue ws, resp
          else
            ws.send resp.to_json
          end
        }
      end

      # Batch version for process_msg
      #
      # @param [Object] ws
      # @param [Array]  pkgs
      #
      # @private
      def process_msgs ws, pkgs
        pkgs.each { |pkg| process_msg ws, pkg }
      end

      # Enqueue the response
      #
      # @param [Object] ws
      #
      # @private
      def enqueue ws, resp
      end

      # ip filter
      #
      # @param [Object] obj
      #
      # @private
      def ip_filter obj
      end
    end
  end
end
