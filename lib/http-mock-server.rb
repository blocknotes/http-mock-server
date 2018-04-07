require 'pry'
require 'sinatra/base'
require 'yaml'

require_relative File.expand_path('../version.rb', __FILE__)

$config_file = ENV['MOCK_CONFIG']
unless ARGV.empty?
  case ARGV[0]
  when '-v'
    puts "http-mock-server v#{MOCK_SERVER_VERSION}"
    exit 0
  when '-h'
    puts "http-mock-server v#{MOCK_SERVER_VERSION}\n"
    puts 'Syntax: http-mock-server config.yml'
    exit 0
  else
    if File.exist?(ARGV[0])
      $config_file = ARGV[0]
      puts "> Using config file: #{$config_file}"
    end
  end
end
$config_file ||= 'mock.yml'

begin
  $config = YAML.safe_load File.read($config_file)
rescue StandardError => _ignored
  puts "Config file not found: #{$config_file}"
  exit 1
end
$config['config'] ||= {}
$config['config']['namespace'] ||= ''
$config['routes'] ||= []

# Main app class
class HttpMockServer < Sinatra::Base
  MIME_JSON = ['application/json'].freeze
  CORS_HEADERS = {
    'Access-Control-Allow-Origin'  => '*',
    'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, Token'
  }.freeze
  METHODS = %w[connect delete get head options patch post put trace].freeze

  # set :environment, :development
  set :port, $config['config']['port'] if $config['config']['port']
  set :server_settings, timeout: $config['config']['timeout'] || 0

  configure do
  end

  before do
    content_type :json
    headers(CORS_HEADERS) unless $config['config']['no_cors']
  end

  $config['routes'].each_with_index do |rt, i|
    method = nil
    METHODS.each do |m|
      method = m if rt[m]
      break if method
    end
    next unless method
    send method, $config['config']['namespace'] + rt[method] do
      route = reload_route i
      code = route['status'] || 200
      log code, method.upcase, request.path
      (route['headers'] || {}).each do |k, v|
        response.headers[k] = v
      end
      status code
      if route['body']
        content = route['body'].dup
        traverse! content
        content.to_json
      end
    end
  end

  if $config['not_found']
    not_found do
      route = reload_route(-1)
      code = route['status'] || 404
      log code, request.path, ''
      (route['headers'] || {}).each do |k, v|
        response.headers[k] = v
      end
      status code
      if route['body']
        content = route['body'].dup
        traverse! content
        content.to_json
      end
    end
  end

  def log(code, method, path)
    print "#{Time.now.strftime('%F %T')} - [#{code}] #{method} #{path}\n"
    return unless $config['config']['verbose']
    if MIME_JSON.include? env['CONTENT_TYPE']
      request.body.rewind
      data = JSON.parse request.body.read
      print "  PARAMS_JSON: #{data}\n" unless data.empty?
    else
      pars = params.dup
      pars.delete 'captures'
      pars.delete 'splat'
      print "  PARAMS_DATA: #{pars}\n" if pars.any?
    end
  end

  def interpolate(input)
    vars = input.to_s.scan(/\#{(.*?)}/).flatten.map { |t| eval(t) }
    input.to_s.gsub(/\#{(.*?)}/, '%s') % vars
  end

  def reload_route(route_id)
    config = YAML.safe_load File.read($config_file) || {}
    return config['not_found'] || {} if route_id < 0
    return {} if !config['routes'] || !config['routes'][route_id]
    config['routes'][route_id]
  end

  def traverse!(hash)
    hash.each do |k, v|
      if v.is_a?(Hash) || v.is_a?(Array)
        traverse! v
      elsif v
        hash[k] = interpolate v
      end
    end
  end

  run! if app_file == $PROGRAM_NAME || ENV['http_mock_server_bin']
end
