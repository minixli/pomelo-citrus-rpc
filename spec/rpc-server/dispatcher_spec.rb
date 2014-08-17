# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 5 July 2014

require File.expand_path('../../spec_helper', __FILE__)

describe Dispatcher do
  include Dispatcher

  services = {}
  services['user'] = {}
  services['sys'] = {}

  services['user']['addOneRemote'] = Object.new
  services['user']['addOneRemote'].define_singleton_method :do, proc{ |num, &block|
    block.call nil, num + 1
  }

  services['sys']['addTwoRemote'] = Object.new
  services['sys']['addTwoRemote'].define_singleton_method :do, proc{ |num, &block|
    block.call nil, num + 2
  }

  it 'should dispatch message to the corresponding procedural' do
    callback_count = 0

    value = 0
    msg1 = {
      'namespace' => 'user',
      'service' => 'addOneRemote',
      'method' => 'do',
      'args' => [value]
    }
    msg2 = {
      'namespace' => 'sys', 
      'service' => 'addTwoRemote',
      'method' => 'do',
      'args' => [value]
    }

    dispatch(msg1, services) { |err, result|
      expect(err).to be_nil
      expect(result).to be
      expect(result).to eql (value + 1)
      callback_count = callback_count + 1
    }

    dispatch(msg2, services) { |err, result|
      expect(err).to be_nil
      expect(result).to be
      expect(result).to eql (value + 2)
      callback_count = callback_count + 1
    }

    expect(callback_count).to eql 2
  end

  it 'should return an error if the service or method not exist' do
    callback_count = 0

    value = 0
    msg1 = {
      'namespace' => 'user',
      'service' => 'addXRemote',
      'method' => 'do',
      'args' => [value]
    }
    msg2 = {
      'namespace' => 'user',
      'service' => 'addOneRemote',
      'method' => 'foo',
      'args' => [value] }

    dispatch(msg1, services) { |err, result|
      expect(err).to be
      expect(result).to be_nil
      callback_count = callback_count + 1
    }

    dispatch(msg2, services) { |err, result|
      expect(err).to be
      expect(result).to be_nil
      callback_count = callback_count + 1
    }

    expect(callback_count).to eql 2
  end
end
