# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../spec_helper', __FILE__)

describe Server do

  dirname = File.expand_path File.dirname(__FILE__)
  records = [
    { :namespace => 'user', :path => dirname + '/../mock-remote/area' },
    { :namespace => 'sys', :path => dirname + '/../mock-remote/connector' }
  ]

  port = 3333

  describe '#create' do
    it 'should be ok by passing port and paths argument' do
      error_count = 0
      close_count = 0

      server = Server.new :records => records, :port => port
      expect(server).to be

      server.on(:error) { |err| error_count = error_count + 1 }
      server.on(:closed) { close_count = close_count + 1 }

      EM.run {
        server.start
        server.stop

        EM.add_timer(0.1) {
          expect(error_count).to eq 0
          expect(close_count).to eq 1
          EM.stop_event_loop
        }
      }
    end

    it 'should change the default acceptor class by passing acceptor class argument' do
      construct_count = 0
      listen_count = 0
      close_count = 0

      MockAcceptor = Class.new do
        define_method(:initialize) { |*args|
          construct_count = construct_count + 1
        }

        define_method(:listen) { |*args|
          listen_count = listen_count + 1
        }

        define_method(:close) { |*args|
          close_count = close_count + 1
        }
 
        define_method(:on) { |*args| }

        define_method(:emit) { |*args| }
      end

      server = Server.new :records => records, :port => port, :acceptor_class => MockAcceptor
      expect(server).to be

      EM.run {
        server.start
        server.stop

        EM.add_timer(0.1) {
          expect(construct_count).to eq 1
          expect(listen_count).to eq 1
          expect(close_count).to eq 1
          EM.stop_event_loop
        }
      }
    end
  end
end
