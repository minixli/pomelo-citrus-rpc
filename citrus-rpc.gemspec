# Author:: MinixLi (gmail: MinixLi1986)
# Homepage:: http://citrus.inspawn.com
# Date:: 8 July 2014

$:.push File.expand_path('../lib', __FILE__)

require 'citrus-rpc/version'

Gem::Specification.new do |spec|
  spec.name        = 'pomelo-citrus-rpc'
  spec.version     = CitrusRpc::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ['MinixLi']
  spec.email       = 'MinixLi1986@gmail.com'
  spec.description = %q{pomelo-citrus-rpc is a simple clone of pomelo-rpc, it provides the infrastructure of RPC between multi-server processes}
  spec.summary     = %q{pomelo-rpc clone written in Ruby using EventMachine}
  spec.homepage    = 'https://github.com/minixli/pomelo-citrus-rpc'
  spec.license     = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency('eventmachine', '~> 0')
  spec.add_dependency('json', '~> 0')
  spec.add_dependency('websocket-eventmachine-client', '~> 0')
  spec.add_dependency('websocket-eventmachine-server', '~> 0')

  spec.add_dependency('citrus-loader', '~> 0')
  spec.add_dependency('citrus-logger', '~> 0')
end
