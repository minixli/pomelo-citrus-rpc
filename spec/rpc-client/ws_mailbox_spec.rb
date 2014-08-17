# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 7 July 2014

require File.expand_path('../../spec_helper', __FILE__)

describe WsMailBox do

  dirname = File.expand_path File.dirname(__FILE__)
  records = [
    { :namespace => 'user', :server_type => 'area', :path => dirname + '/../mock-remote/area' },
    { :namespace => 'sys', :server_type => 'connector', :path => dirname + '/../mock-remote/connector' }
  ]

  port = 3333

  server = { :server_id => 'area-server-1', :host => '127.0.0.1', :port => port }

  value = 1
  msg = {
    'namespace' => 'user',
    'server_type' => 'area',
    'service' => 'addOneRemote',
    'method' => 'do',
    'args' => [value]
  };

  describe '#create' do
    it 'should be ok for creating a mailbox and connect to the right remote server' do
      mailbox = WsMailBox.new server
      expect(mailbox).to be

      EM.run {
        Server.new( :records => records, :port => port ).start

        mailbox.connect { |err|
          expect(err).to be_nil
          EM.stop_event_loop
        }
      }
    end

    it 'should return an error if connect fail' do
      bad_server = { :server_id => 'area-server-1', :host => '127.0.0.1', :port => -1000 }

      mailbox = WsMailBox.new bad_server
      expect(mailbox).to be

      EM.run {
        mailbox.connect { |err|
          expect(err).to be
          EM.stop_event_loop
        }
      }
    end
  end

  describe '#send' do
    it 'should send request to the right remote server and get response from callback' do
      EM.run {
        Server.new( :records => records, :port => port ).start

        mailbox = WsMailBox.new server
        expect(mailbox).to be

        mailbox.connect { |err|
          expect(err).to be_nil

          mailbox.send(msg, nil, proc{ |send_err, err, res|
            expect(res).to be
            expect(res).to eql msg['args'][0] + 1
            EM.stop_event_loop
          })
        }
      }
    end

    it 'should distinguish different services and keep the right request/response relationship' do
      callback_count = 0

      value = 1
      msg1 = {
        'namespace' => 'user',
        'server_type' => 'area',
        'service' => 'addOneRemote',
        'method' => 'do',
        'args' => [value]
      }
      msg2 = {
        'namespace' => 'user',
        'server_type' => 'area',
        'service' => 'addOneRemote',
        'method' => 'add_two',
        'args' => [value]
      }
      msg3 = {
        'namespace' => 'user',
        'server_type' => 'area',
        'service' => 'addThreeRemote',
        'method' => 'do',
        'args' => [value]
      }

      EM.run {
        Server.new( :records => records, :port => port ).start

        mailbox = WsMailBox.new server
        expect(mailbox).to be

        mailbox.connect { |err|
          err.should be_nil

          mailbox.send(msg1, nil, proc{ |send_err, err, res|
            expect(res).to be
            expect(res).to eql msg1['args'][0] + 1
            callback_count = callback_count + 1
          })

          mailbox.send(msg2, nil, proc{ |send_err, err, res|
            expect(res).to be
            expect(res).to eql msg2['args'][0] + 2
            callback_count = callback_count + 1
          })

          mailbox.send(msg3, nil, proc{ |send_err, err, res|
            expect(res).to be
            expect(res).to eql msg3['args'][0] + 3
            callback_count = callback_count + 1
          })
        }

        EM.add_timer(0.1) {
          expect(callback_count).to eql 3
          EM.stop_event_loop
        }
      }
    end
  end

  describe '#close' do
    it 'should emit a close event when mailbox close' do
    end
  end
end
