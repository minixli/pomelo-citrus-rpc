# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../spec_helper', __FILE__)

describe Client do

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

  describe '#create' do
    it 'should be ok when created with empty options' do
      client = Client.new
      expect(client).to be_an_instance_of Client

      EM.run {
        client.start { |err|
          expect(err).to be_nil
          client.stop true
        }

        EM.add_timer(0.1) { EM.stop_event_loop }
      }
    end

    it 'should add proxies by add_proxies method' do
      client = Client.new
      expect(client).to be_an_instance_of Client

      client.add_proxies records
      records.each { |record|
        namespace = record[:namespace]
        server_type = record[:server_type]
        expect(client.proxies).to respond_to namespace
        expect(client.proxies[namespace]).to respond_to server_type
      }
    end

    it 'should replace the default router when created by passing router argument' do
      route_count = 0
      callback_count = 0

      server = server_list[1]
      server_id = server[:id]

      router = Proc.new do |route_param, msg, route_context, &block|
        route_count = route_count + 1
        block.call nil, server_id
      end

      EM.run {
        server_list.each { |server|
          Server.new( :records => records, :port => server[:port],
            :context => { :server_id => server[:id] }).start
        }

        client = Client.new :router => router
        client.add_proxies records
        client.add_server server

        client.start { |err|
          expect(err).to be_nil

          client.proxies.sys.connector.whoAmIRemote.do(nil) { |err, sid|
            callback_count = callback_count + 1
            expect(sid).to eq server_id
          }
        }

        EM.add_timer(0.1) {
          expect(route_count).to eq 1
          expect(callback_count).to eq 1
          EM.stop_event_loop
        }
      }
    end
  end

  describe '#status' do
    it 'should return an error if started twice' do
      client = Client.new
      EM.run {
        client.start { |err|
          expect(err).to be_nil
          client.start { |err|
            expect(err).to be
          }
        }

        EM.add_timer(0.1) { EM.stop_event_loop }
      }
    end

    it 'should ignore the later operation if stopped twice' do
      client = Client.new
      EM.run {
        client.start { |err|
          expect(err).to be_nil
          client.stop
          client.stop
        }

        EM.add_timer(0.1) { EM.stop_event_loop }
      }
    end

    it 'should return an error when doing rpc invoke with the client not started' do
      client = Client.new
      EM.run {
        client.rpc_invoke(server_list[0][:id], '') { |err|
          expect(err).to be
        }

        EM.add_timer(0.1) { EM.stop_event_loop }
      }
    end

    it 'should return an error when doing rpc invoke after the client stopped' do
      server_id = server_list[0][:id]

      client = Client.new
      client.add_server server_list[0]

      EM.run {
        server_list.each { |server|
          Server.new( :records => records, :port => server[:port],
            :context => { :server_id => server[:id] }).start
        }

        msg = {
          'namespace' => 'user',
          'server_type' => 'area',
          'service' => 'whoAmIAreaRemote',
          'method' => 'do',
          'args' => []
        };

        client.start { |err|
          expect(err).to be_nil

          client.rpc_invoke(server_id, msg) { |err|
            expect(err).to be_nil
            client.stop true
            EM.add_timer(0.1) {
              client.rpc_invoke(server_id, msg) { |err|
                expect(err).to be
              }
            }
          }
        }

        EM.add_timer(0.2) { EM.stop_event_loop }
      }
    end
  end
end
