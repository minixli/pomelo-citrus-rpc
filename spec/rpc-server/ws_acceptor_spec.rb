# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../spec_helper', __FILE__)
require File.expand_path('../client/mock-ws-client', __FILE__)

describe WsAcceptor do

  port = 3333

  describe '#listen' do
    it 'should be ok started listening on a valid port and closed event should be emitted when closed' do
      error_count = 0
      close_count = 0

      acceptor = WsAcceptor.new
      expect(acceptor).to be

      acceptor.on(:error) { |err| error_count = error_count + 1 }
      acceptor.on(:closed) { |closed| close_count = close_count + 1 }

      EM.run {
        acceptor.listen port
        acceptor.close

        EM.add_timer(0.1) {
          expect(error_count).to eql 0
          expect(close_count).to eql 1
          EM.stop_event_loop
        }
      }
    end

    it 'should emit an error when listening on a port in use' do
      error_count = 0

      acceptor = WsAcceptor.new
      expect(acceptor).to be

      acceptor.on(:error) { |err|
        expect(err).to be
        error_count = error_count + 1
      }

      EM.run {
        acceptor.listen 80

        EM.add_timer(0.1) {
          expect(error_count).to eql 1
          EM.stop_event_loop
        }
      }
    end
  end

  describe '#new message callback' do
    it('should invoke the callback function with the same msg and return response to remote client by cb') {
      server_callback_count = 0
      client_callback_count = 0

      origin_msg = {
        'service' => 'xxx.yyy.zzz',
        'method' => 'someMethod',
        'args' => [ 1, 'a', { 'param' => 100 } ]
      }

      acceptor = WsAcceptor.new do |msg, &block|
        expect(msg).to eql origin_msg
        server_callback_count = server_callback_count + 1
        block.call msg
      end
      expect(acceptor).to be

      EM.run {
        acceptor.listen port

        client = MockWsClient.new
        client.connect('127.0.0.1', port) {
          client.send(origin_msg) { |msg|
            expect(msg).to eql origin_msg
            client_callback_count = client_callback_count + 1
          }
        }

        EM.add_timer(0.1) {
          expect(server_callback_count).to eql 1
          expect(client_callback_count).to eql 1
          EM.stop_event_loop
        }
      }
    }

    it 'should keep relationship with request and response' do
      server_callback_count = 0
      client_callback_count = 0

      origin_msg1 = {
        'service' => 'xxx.yyy.zzz1',
        'method' => 'someMethod1',
        'args' => [ 1, 'a', { 'param' => 100 } ]
      }
      origin_msg2 = {
        'service' => 'xxx.yyy.zzz2',
        'method' => 'someMethod2',
        'args' => [ 1, 'a', { 'param' => 100} ]
      }

      acceptor = WsAcceptor.new do |msg, &block|
        server_callback_count = server_callback_count + 1
        block.call msg
      end
      expect(acceptor).to be

      EM.run {
        acceptor.listen port

        client = MockWsClient.new
        client.connect('127.0.0.1', port) {
          client.send(origin_msg1) { |msg|
            expect(msg).to eql origin_msg1
            client_callback_count = client_callback_count + 1
          }
          client.send(origin_msg2) { |msg|
            expect(msg).to eql origin_msg2
            client_callback_count = client_callback_count + 1
          }
        }

        EM.add_timer(0.1) {
          expect(server_callback_count).to eql 2
          expect(client_callback_count).to eql 2
          EM.stop_event_loop
        }
      }
    end
  end
end
