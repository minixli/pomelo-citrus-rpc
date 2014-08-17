# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

module CitrusRpc
  # RpcClient
  #
  #
  module RpcClient
    # Router
    #
    #
    module Router
      # Calculate route info and return an appropriate server id
      #
      # @param [Object] session
      # @param [Hash]   msg
      # @param [Object] context
      def df_route session, msg, context, &block
      end

      # Random algorithm for calculating server id
      #
      # @param [Object] client
      # @param [String] server_type
      # @param [Hash]   msg
      def rd_route client, server_type, msg, &block
      end

      # Round-Robin algorithm for calculating server id
      #
      # @param [Object] client
      # @param [String] server_type
      # @param [Hash]   msg
      def rr_route client, server_type, msg, &block
      end

      # Weight-Round-Robin algorithm for calculating server id
      #
      # @param [Object] client
      # @param [String] server_type
      # @param [Hash]   msg
      def wrr_route client, server_type, msg, &block
      end

      # Least-Active algorithm for calculating server id
      #
      # @param [Object] client
      # @param [String] server_type
      # @param [Hash]   msg
      def la_route client, server_type, msg, &block
      end

      # Consistent-Hash algorithm for calculating server id
      #
      # @param [Object] client
      # @param [String] server_type
      # @param [Hash]   msg
      def ch_route client, server_type, msg, &block
      end
    end
  end
end
