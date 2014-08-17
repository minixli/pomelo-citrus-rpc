# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require 'websocket-eventmachine-client'

class MockWsClient
  def initialize
    @cur_id = 0
    @requests = {}
  end

  def connect host, port, &block
    @ws = WebSocket::EventMachine::Client.connect :uri => 'ws://' + host + ':' + port.to_s
    @ws.onopen {
      block.call
    }
    @ws.onmessage { |msg, type|
      begin
        pkg = JSON.parse msg
      rescue => err
      end

      pkg_id = pkg['id']
      pkg_resp = pkg['resp']

      callback = @requests[pkg_id]
      callback.call *pkg_resp

      @requests.delete pkg_id
    }
    @ws.onerror { |err| }
    @ws.onclose { |code, reason| }
  end

  def send msg, &callback
    id = @cur_id
    @requests[id] = callback

    @cur_id = @cur_id + 1

    @ws.send({ 'id' => id, 'msg' => msg }.to_json)
  end

  def close
    @ws.close
  end
end
