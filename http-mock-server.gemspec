lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative File.expand_path('../lib/version.rb', __FILE__)

Gem::Specification.new do |spec|
  spec.name        = 'http-mock-server'
  spec.version     = MOCK_SERVER_VERSION
  spec.authors     = ['Mattia Roccoberton']
  spec.email       = 'mat@blocknot.es'
  spec.homepage    = 'https://github.com/blocknotes/http-mock-server'
  spec.summary     = 'HTTP Mock Server'
  spec.description = 'A Ruby HTTP Mock Server based on Sinatra'
  spec.platform    = Gem::Platform::RUBY
  spec.license     = 'MIT'

  # spec.files         = `git ls-files -z`.split("\x0")
  spec.files  = Dir['lib/*.rb'] + Dir['bin/*']
  spec.files += Dir['[A-Z]*'] + Dir['spec/**/*']
  spec.files.reject! { |fn| fn.include? 'CVS' }

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.0.0'
  spec.add_runtime_dependency 'pry', '~> 0.11'
  spec.add_runtime_dependency 'sinatra', '~> 2.0'

  spec.add_development_dependency 'rack-test', '~> 1.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
end
