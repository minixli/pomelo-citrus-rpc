# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 4 July 2014

require 'citrus-rpc/rpc-client/mailstation'
require 'citrus-rpc/rpc-client/proxy'
require 'citrus-rpc/rpc-client/router'

module CitrusRpc
  # RpcClient
  #
  #
  module RpcClient
    # Client
    #
    # @example
    #
    # Create a new rpc client
    #
    #  client = CitrusRpc::RpcClient::Client.new
    #
    # Add a proxy
    #
    #  dirname = File.expand_path File.dirname(__FILE__)
    #  client.add_proxy(
    #    :namespace => 'user',
    #    :server_type => 'test',
    #    :path => dirname + '/remote/test' # remote service interface path
    #  )
    #
    # Add a remote server
    #
    #  client.add_server(
    #    :server_id => 'test-server-1',
    #    :server_type => 'test',
    #    :host => '127.0.0.1',
    #    :port => 3333
    #  )
    #
    # Do the rpc invoke
    #
    #  client.start do |err|
    #    client.proxies.sys.connector.WhoAmIRemote.do(nil, 'hello') do |err, resp|
    #      ...
    #    end
    #  end
    #
    class Client
      include CitrusLoader

      include Proxy
      include Router

      attr_reader :proxies

      # Create a new rpc client
      #
      # @param [Hash] args Options
      #
      # @option args [Object] context
      # @option args [Object] route_context
      # @option args [#call]  router
      # @option args [String] router_type
      def initialize args={}
        @args = args

        @context = @args[:context]
        @route_context = @args[:route_context]

        @router = @args[:router] || method(:df_route)
        @router_type = @args[:router_type]

        @proxies = OpenStruct.new
        @station = MailStation.new args

        @state = :state_inited
      end

      # Start the rpc client which would try to connect the remote servers
      def start
        unless @state == :state_inited
          block_given? and yield Exception.new 'rpc client has started'
          return
        end

        @station.start { |err|
          if err
            block_given? and yield err
            return
          end
          @state = :state_started
          block_given? and yield
        }
      end

      # Stop the rpc client
      #
      # @param [Boolean] force
      def stop force=false
        unless @state == :state_started
          return
        end
        @state = :state_closed
        @station.stop force
      end

      # Add a new proxy to the rpc client which would override the proxy under
      # the same key
      #
      # @param [Hash] record
      def add_proxy record
        return unless record

        proxy = generate_proxy record
        return unless proxy

        insert_proxy @proxies, record[:namespace], record[:server_type], proxy
      end

      # Batch version for add_proxy
      #
      # @param [Array] records
      def add_proxies records
        if records && records.length > 0
          records.each { |record| add_proxy record }
        end
      end

      # Add new remote server to the rpc client
      #
      # @param [Hash] server
      def add_server server
        @station.add_server server
      end

      # Batch version for add new remote server
      #
      # @param [Array] servers
      def add_servers servers
        @station.add_servers servers
      end

      # Remove remote server from the rpc client
      #
      # @param [String] id
      def remove_server id
        @station.remove_server id
      end

      # Batch version for remove remote server
      #
      # @param [Array] server_ids
      def remove_servers ids
        @station.remove_servers ids
      end

      # Replace remote servers
      #
      # @param [Array] servers
      def replace_servers servers
        @station.replace_servers servers
      end

      # Do the rpc invoke directly
      #
      # @param [String] server_id
      # @param [Hash]   msg
      def rpc_invoke server_id, msg, &block
        unless @state == :state_started
          block_given? and yield Exception.new 'fail to do rpc invoke for client is not running'
          return
        end
        @station.dispatch server_id, msg, @args, block
      end

      # Add rpc before filter
      #
      # @param [#call] filter
      def before filter
        @station.before filter
      end

      # Add rpc after filter
      #
      # @param [#call] filter
      def after filter
        @station.after filter
      end

      # Add rpc filter
      #
      # @param [#call] filter
      def filter filter
        @station.filter filter
      end

      # Set rpc filter error handler
      #
      # @param [#call] handler
      def set_error_handler handler
        @station.error_handler = handler
      end

      private

      # Generate proxies for remote servers
      #
      # @param [Hash] record
      #
      # @private
      def generate_proxy record
        res = OpenStruct.new;
        remotes = load_app_remote record[:path]
        remotes.each { |service, remote|
          res[service] = create_proxy(
            :remote => remote, :service => service, :attach => record, :proxy_cb => method(:proxy_cb)
          )
        }
        res
      end

      # Proxy callback
      #
      # @param [String]  service
      # @param [Symbol]  method
      # @param [Hash]    attach
      # @param [Boolean] is_to_specified_server
      #
      # @private
      def proxy_cb service, method, attach, is_to_specified_server, *args, &block
        unless @state == :state_started
          return
        end
        unless args.length > 0
          return
        end

        route_param = args.shift
        server_type = attach[:server_type]
        msg = { :namespace => attach[:namespace], :server_type => server_type,
          :service => service, :method => method, :args => args }

        if is_to_specified_server
          rpc_to_specified_server msg, server_type, route_param, &block
        else
          get_route_target(server_type, msg, route_param) { |err, server_id|
            if err
              block_given? and block.call err
            else
              rpc_invoke server_id, msg, &block
            end
          }
        end
      end

      # Calculate remote target server id for rpc client
      #
      # @param [String] server_type
      # @param [Hash]   msg
      # @param [Object] route_param
      #
      # @private
      def get_route_target server_type, msg, route_param, &block
        if @router_type
          router = case @router_type
                   when :roundrobin
                     method :rr_route
                   when :weight_roundrobin
                     method :wrr_route
                   when :least_active
                     method :la_route
                   when :consistent_hash
                     method :ch_route
                   else
                     method :rd_route
                   end
          router.call(self, server_type, msg) { |err, server_id|
            block_given? and yield err, server_id
          }
        else
          unless @router.respond_to? :call
            block_given? and yield Exception.new 'invalid router method'
            return
          end
          @router.call(route_param, msg, @route_context) { |err, server_id|
            block_given? and yield err, server_id
          }
        end
      end

      # Rpc to specified server id or servers
      #
      # @param [Hash]   msg
      # @param [String] server_type
      # @param [String] route_param
      #
      # @private
      def rpc_to_specified_server msg, server_type, route_param, &block
        unless route_param.instance_of? String
          return
        end

        if route_param == '*'
          @station.servers.each { |server_id, server|
            if server[:server_type] == server_type
              rpc_invoke server_id, msg, &block
            end
          }
        else
          rpc_invoke route_param, msg, &block
        end
      end
      
      # Add proxy into array
      #
      # @param [Object] proxies
      # @param [String] namespace
      # @param [String] server_type
      # @param [Object] proxy
      #
      # @private
      def insert_proxy proxies, namespace, server_type, proxy
        proxies[namespace] ||= OpenStruct.new
        proxies[namespace][server_type] = proxy
      end
    end
  end
end
