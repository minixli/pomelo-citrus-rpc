# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 7 July 2014

require 'citrus-rpc/rpc-client/mailboxes/ws_mailbox'
require 'citrus-rpc/util/constants'

module CitrusRpc
  # RpcClient
  #
  #
  module RpcClient
    # MailStation
    #
    #
    class MailStation
      include Utils::EventEmitter

      attr_reader :servers, :mailbox_class

      # Create a new mail station
      #
      # @param [Hash] args Options
      #
      # @option args [Class]   mailbox_class
      # @option args [Integer] pending_size
      def initialize args={}
        @args = args
        @servers = {}       # [Hash] server id => info
        @servers_map = {}   # [Hash] server type => servers array
        @onlines = {}       # [Hash] server id => true or false
        @mailbox_class = @args[:mailbox_class] || WsMailBox

        # filters
        @befores = {}
        @afters = {}

        # pending request queues
        @pendings = {}
        @pending_size = @args[:pending_size] || Constants::DefaultParams::PendingSize

        # onnecting remote server mailbox map
        @connecting = {}

        # working mailbox map
        @mailboxes = {}

        @state = :state_inited
      end

      # Start station and connect all mailboxes to remote servers
      def start
        unless @state == :state_inited
          block_given? and yield Exception.new 'station has started'
          return
        end
        EM.next_tick { @state = :state_started; block_given? and yield }
      end

      # Stop station and all its mailboxes
      #
      # @param [Boolean] force
      def stop force=false
        unless @state == :state_started
          return
        end
        @state = :state_closed

        close_all = Proc.new {
          @mailboxes.each { |server_id, mailbox| mailbox.close }
        }
        if force
          close_all.call
        else
          EM.add_timer(Constants::DefaultParams::GraceTimeout) { close_all.call }
        end
      end

      # Add a new server info into the mail station
      #
      # @param [Hash] server_info
      def add_server server_info
        return unless server_info && server_info[:id]

        id = server_info[:id]
        type = server_info[:server_type]

        @servers[id] = server_info
        @onlines[id] = true

        @servers_map[type] ||= []
        @servers_map[type] << id

        emit :add_server, id
      end

      # Batch version for add new server info
      #
      # @param [Array] server_infos
      def add_servers server_infos
        return unless server_infos && server_infos.length > 0
        server_infos.each { |server_info| add_server server_info }
      end

      # Remove a server info from the mail station and remove
      # the mailbox instance associated with the server id.
      #
      # @param [String] id
      def remove_server id
        @onlines[id] = false

        if @servers[id]
          type = @servers[id][:server_type]
          @servers_map[type].delete id
        end

        if mailbox = @mailboxes[id]
          mailbox.close
          @mailboxes.delete id
        end

        emit :remove_server, id
      end

      # Batch version for remove remote servers
      #
      # @param [Array] ids
      def remove_servers ids
        return unless ids && ids.length > 0
        ids.each { |id| remove_server ids }
      end

      # Clear station infomation
      def clear_station
        @onlines = {}
        @servers_map = {}
      end

      # Replace servers
      #
      # @param [Array] server_infos
      def replace_servers server_infos
        clear_station
        return unless server_infos && server_infos.length > 0

        server_infos.each { |server_info|
          id = server_info[:server_id]
          type = server_info[:server_type]

          @onlines[id] = true
          @servers[id] = server_info

          @servers_map[type] ||= []
          @servers_map[type] << id
        }
      end

      # Dispatch rpc message to the mailbox
      #
      # @param [String] server_id
      # @param [Hash]   msg
      # @param [Hash]   opts
      # @param [#call]  block
      def dispatch server_id, msg, opts, block
        unless @state == :state_started
          block.call Exception.new 'client is not running now'
          return
        end

        args = [server_id, msg, opts, block]

        unless @mailboxes[server_id]
          # try to connect remote server if mailbox instance not exist yet
          unless lazy_connect server_id, @mailbox_class
            emit :error
          end
          # push request to the pending queue
          add_to_pending server_id, args
          return
        end

        # if the mailbox is connecting to remote server
        if @connecting[server_id]
          add_to_pending server_id, args
          return
        end

        send = Proc.new { |err, server_id, msg, opts|
          if err
            return
          end
          unless mailbox = @mailboxes[server_id]
            return
          end
          mailbox.send(msg, opts, proc{ |*args|
            if send_err = args[0]
              emit :error
              return
            end
            args.shift
            do_filter nil, server_id, msg, opts, @befores, 0, 'after', proc{ |err, server_id, msg, opts|
              if err
              end
              block.call *args
            }
          })
        }

        do_filter nil, server_id, msg, opts, @afters, 0, 'before', send
      end

      # Add a before filter
      #
      # @param [#call] filter
      def before filter
        if filter.instance_of? Array
          @befores.concat filter
          return
        end
        @befores << filter
      end

      # Add after filter
      #
      # @param [#call] filter
      def after filter
        if filter.instance_of? Array
          @afters.concat filter
          return
        end
        @afters << filter
      end

      #  Add before and after filter
      #
      # @param [#call] filter
      def filter filter
        @befores << filter
        @afters << filter
      end

      private

      # Try to connect to remote server
      #
      # @param [String] server_id
      #
      # @private
      def connect server_id
        mailbox = @mailboxes[server_id]
        mailbox.connect { |err|
          if err
            @mailboxes.delete server_id if @mailboxes[server_id]
            return
          end

          mailbox.on(:close) { |id|
            @mailboxes.delete id if @mailboxes[id]
            emit :close, id
          }

          @connecting.delete server_id
          flush_pending server_id
        }
      end

      # Do before or after filter
      #
      # @param [Object]  err
      # @param [String]  server_id
      # @param [Hash]    msg
      # @param [Hash]    opts
      # @param [Array]   filters
      # @param [Integer] index
      # @param [String]  operate
      # @param [#call]   block
      #
      # @private
      def do_filter err, server_id, msg, opts, filters, index, operate, block
        if index >= filters.length || err
          block.call err, server_id, msg, opts
          return
        end

        filter = filters[index]
        if filter.respond_to? :call
          filter.call(server_id, msg, opts) { |target, message, options|
            index += 1
            if target.is_a? Exception
              do_filter target, server_id, msg, opts, filters, index, operate, block
            else
              do_filter nil, target || server_id, message || msg, options || opts, filters, index, operate, block
            end
          }
          return
        end

        index += 1
        do_filter err, server_id, msg, opts, filters, index, operate, block
      end

      # Lazy connect remote server
      #
      # @param [String] server_id
      # @param [Class]  mailbox_class
      #
      # @private
      def lazy_connect server_id, mailbox_class
        unless server = @servers[server_id]
          return false
        end
        unless @onlines[server_id] == true
          return false
        end

        mailbox = mailbox_class.new server, @args
        @connecting[server_id] = true
        @mailboxes[server_id] = mailbox
        connect server_id

        true
      end

      # Add request to pending queue
      #
      # @param [String] server_id
      # @param [Array]  args
      #
      # @private
      def add_to_pending server_id, args
        pending = @pendings[server_id] ||= []
        if pending.length > @pending_size
          return
        end
        pending << args
      end

      # Flush pending queue
      #
      # @param [String] server_id
      #
      # @private
      def flush_pending server_id
        pending = @pendings[server_id]
        mailbox = @mailboxes[server_id]
        return unless pending && pending.length > 0

        unless mailbox
        end

        pending.each { |args| dispatch *args }

        @pendings.delete server_id
      end

      # Error handler 
      #
      # @private
      def error_handler
      end
    end
  end
end
