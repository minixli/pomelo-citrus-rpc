# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../spec_helper', __FILE__)

describe MailStation do

  dirname = File.expand_path File.dirname(__FILE__)
  records = [
    { :namespace => 'user', :server_type => 'area', :path => dirname + '/../mock-remote/area' },
    { :namespace => 'sys', :server_type => 'connector', :path => dirname + '/../mock-remote/connector' }
  ]

  server_list = [
    { :id => 'area-server-1', :server_type => 'area', :host => '127.0.0.1', :port => 3333 },
    { :id => 'connector-server-1', :server_type => 'connector', :host => '127.0.0.1', :port => 4444 },
    { :id => 'connector-server-2', :server_type => 'connector', :host => '127.0.0.1', :port => 5555 }
  ]

  msg = {
    'namespace' => 'user',
    'server_type' => 'area',
    'service' => 'whoAmIAreaRemote',
    'method' => 'do',
    'args' => []
  }

  describe '#create' do
    it 'should be ok when created with empty options' do
      EM.run {
        station = MailStation.new
        expect(station).to be

        station.start { |err|
          expect(err).to be_nil
          EM.stop_event_loop
        }
      }
    end

    it 'should change the default mailbox class by passing mailbox class argument' do
      MockMailBox = Class.new

      station = MailStation.new :mailbox_class => MockMailBox
      expect(station).to be
      expect(station.mailbox_class).to eql MockMailBox
    end
  end

  describe '#add server' do
    it 'should add server info into the mail station' do
      station = MailStation.new
      expect(station).to be

      server_list.each { |server|
        station.add_server server
      }

      servers = station.servers
      server_list.each { |item|
        server = servers[item[:id]]
        expect(server).to be
        expect(server).to eql item
      }
    end
  end

  describe '#dispatch' do
    it 'should send the request to the right remote server and get the response from callback' do
      callback_count = 0
      count = 0

      station = MailStation.new
      expect(station).to be

      server_list.each { |server|
        station.add_server server
      }

      EM.run do
        server_list.each { |server|
          Server.new(
            :records => records,
            :port => server[:port],
            :context => { :server_id => server[:id] }
          ).start
        }

        func = Proc.new { |server_id|
          Proc.new { |err, remote_id|
            expect(remote_id).to be
            expect(remote_id).to eql server_id
            callback_count = callback_count + 1
          }
        }

        station.start { |err|
          server_list.each { |server|
            count = count + 1
            station.dispatch server[:id], msg, nil, func.call(server[:id])
          }
        }

        EM.add_timer(0.1) {
          expect(callback_count).to eql count
          EM.stop_event_loop
        }
      end
    end

    it 'should update the mailbox map by add server after start' do
      callback_count = 0
      count = 0

      station = MailStation.new
      expect(station).to be

      server_list.each { |server|
        station.add_server server
      }

      EM.run {
        server_list.each { |server|
          Server.new(
            :records => records,
            :port => server[:port],
            :context => { :server_id => server[:id] }
          ).start
        }

        server = server_list[0]

        block = Proc.new { |err, remote_id|
          expect(remote_id).to be
          expect(remote_id).to eql server[:id]
          callback_count = callback_count + 1
        }

        station.start { |err|
          station.add_server server
          station.dispatch server[:id], msg, nil, block
        }

        EM.add_timer(0.1) {
          expect(callback_count).to eql 1
          EM.stop_event_loop
        }
      }
    end
  end

  describe '#close' do
    it 'should emit a close event for each mailbox close' do
      close_event_count = 0

      server_ids = []
      mailbox_ids = []

      station = MailStation.new
      expect(station).to be

      EM.run {
        server_list.each { |server|
          Server.new(
            :records => records,
            :port => server[:port],
            :context => { :server_id => server[:id] }
          ).start

          station.add_server server

          server_ids << server[:id]
        }

        server_ids.sort

        func = Proc.new { |server_id|
          Proc.new { |err, remote_id|
            expect(remote_id).to be
            expect(remote_id).to eql server_id
          }
        }

        station.start { |err|
          server_list.each { |server|
            station.dispatch server[:id], msg, nil, func.call(server[:id])
          }
          station.on(:close) { |mailbox_id|
            mailbox_ids << mailbox_id
            close_event_count = close_event_count + 1
          }
        }

        EM.add_timer(0.1) {
          station.stop true
          EM.add_timer(0.1) {
            expect(close_event_count).to eql server_ids.length
            mailbox_ids.sort
            expect(mailbox_ids).to eql server_ids
            EM.stop_event_loop
          }
        }
      }
    end

    it 'should return an error when trying to dispatch message with a closed station' do
      error_count = 0

      station = MailStation.new
      expect(station).to be

      server_list.each { |server|
        station.add_server server
      }

      EM.run do
        station.start { |err|
          station.stop
          server_list.each { |server|
            station.dispatch server[:id], msg, nil, proc{ |err, remote_id|
              expect(err).to be
              error_count = error_count + 1
            }
          }
        }

        EM.add_timer(0.1) {
          expect(error_count).to eql server_list.length
          EM.stop_event_loop
        }
      end
    end
  end
end
