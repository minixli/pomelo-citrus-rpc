# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 4 July 2014

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'eventmachine'
require 'json'
require 'ostruct'

require 'pomelo-citrus-loader'
require 'pomelo-citrus-logger'

require 'citrus-rpc/util/utils'
require 'citrus-rpc/rpc-client/client'
require 'citrus-rpc/rpc-server/server'
