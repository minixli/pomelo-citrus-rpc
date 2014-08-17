# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../client/mock-ws-client', __FILE__)

describe Gateway do

  services = {}
  services['user'] = {}

  services['user']['addOneRemote'] = Object.new
  services['user']['addOneRemote'].define_singleton_method :do, proc{ |num, &block|
    block.call nil, num + 1
  }

  services['user']['addTwoRemote'] = Object.new
  services['user']['addTwoRemote'].define_singleton_method :do, proc{ |num, &block|
    block.call nil, num + 2
  }

  port = 3333
  args = { :services => services, :port => port }

  describe '#start' do
    it 'should be ok when listening on a valid port and closed event should be emitted when stopped' do
      error_count = 0
      close_count = 0

      gateway = Gateway.new args
      expect(gateway).to be

      gateway.on(:error) { |err| error_count = error_count + 1 }
      gateway.on(:closed) { |err| close_count = close_count + 1 }

      EM.run {
        gateway.start
        gateway.stop

        EM.add_timer(0.1) {
          expect(error_count).to eql 0
          expect(close_count).to eql 1
          EM.stop_event_loop
        }
      }
    end

    it 'should emit an error when listening on a port in use' do
      error_count = 0

      gateway = Gateway.new :services => services, :port => 80
      expect(gateway).to be

      gateway.on(:error) { |err|
        expect(err).to be
        error_count = error_count + 1
      }

      EM.run {
        gateway.start

        EM.add_timer(0.1) {
          expect(error_count).to eql 1
          EM.stop_event_loop
        }
      }
    end
  end

  describe '#service' do
    it 'should provide rpc service to remote clients' do
      callback_count = 0
      value = 1
      msg = {
        'namespace' => 'user',
        'service' => 'addOneRemote',
        'method' => 'do',
        'args' => [value]
      }

      gateway = Gateway.new args
      expect(gateway).to be

      EM.run {
        gateway.start

        client = MockWsClient.new
        client.connect('127.0.0.1', port) {
          client.send(msg) { |err, resp|
            expect(resp).to eql (value + 1)
            callback_count = callback_count + 1
          }
        }

        EM.add_timer(0.1) {
          expect(callback_count).to eql 1
          EM.stop_event_loop
        }
      }
    end

    it "should send back an error if service doesn't exist" do
      callback_count = 0
      value = 1
      msg = {
        'namespace' => 'user',
        'service' => 'addXRemote',
        'method' => 'do',
        'args' => [value]
      }

      gateway = Gateway.new args
      expect(gateway).to be

      EM.run do
        gateway.start

        client = MockWsClient.new
        client.connect('127.0.0.1', port) {
          client.send(msg) { |err, resp|
            expect(err).to be
            expect(resp).to be_nil
            callback_count = callback_count + 1
          }
        }

        EM.add_timer(0.1) {
          expect(callback_count).to eql 1
          EM.stop_event_loop
        }
      end
    end

    it 'should keep relationship with the request and response' do
      callback_count = 0

      value1 = 1
      msg1 = {
        'namespace' => 'user',
        'service' => 'addOneRemote',
        'method' => 'do',
        'args' => [value1]
      }

      value2 = 2
      msg2 = {
        'namespace' => 'user',
        'service' => 'addOneRemote',
        'method' => 'do',
        'args' => [value2]
      }

      value3 = 3
      msg3 = {
        'namespace' => 'user',
        'service' => 'addTwoRemote',
        'method' => 'do',
        'args' => [value3]
      }

      value4 = 4
      msg4 = {
        'namespace' => 'user',
        'service' => 'addTwoRemote',
        'method' => 'do',
        'args' => [value4]
      }

      gateway = Gateway.new args
      expect(gateway).to be

      EM.run {
        gateway.start

        client = MockWsClient.new
        client.connect('127.0.0.1', port) {
          client.send(msg1) { |err, resp|
            expect(resp).to eql (value1 + 1)
            callback_count = callback_count + 1
          }

          client.send(msg2) { |err, resp|
            expect(resp).to eql (value2 + 1)
            callback_count = callback_count + 1
          }

          client.send(msg3) { |err, resp|
            expect(resp).to eql (value3 + 2)
            callback_count = callback_count + 1
          }

          client.send(msg4) { |err, resp|
            expect(resp).to eql (value4 + 2)
            callback_count = callback_count + 1
          }
        }

        EM::Timer.new(0.1) {
          expect(callback_count).to eql 4
          EM.stop_event_loop
        }
      }
    end
  end
end
