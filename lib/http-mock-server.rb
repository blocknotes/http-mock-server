# coding: utf-8
require 'pry'
require 'sinatra/base'
require 'yaml'

$config_file = ENV['MOCK_CONFIG']
if ARGV.length > 0
  case ARGV[0]
  when '-h'
    puts "#{$0} config.yml"
    exit 0
  else
    if File.exist?(ARGV[0])
      $config_file = ARGV[0]
      puts "> Using config file: #{$config_file}"
    end
  end
end
$config_file ||= 'mock.yml'

$config = YAML.load File.read($config_file) rescue begin
    puts "Config file not found: #{$config_file}"
    exit 1
  end
$config['config'] ||= {}
$config['config']['namespace'] ||= ''
$config['routes'] ||= []

class HttpMockServer < Sinatra::Base
  MIME_JSON = ['application/json']
  CORS_HEADERS = {
    'Access-Control-Allow-Origin'  => '*',
    'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, Token',
  }
  METHODS = %w(connect delete get head options patch post put trace)

  # set :environment, :development
  set :port, $config['config']['port'] if $config['config']['port']
  set :server_settings, timeout: $config['config']['timeout'] || 0

  configure do
  end

  before do
    content_type :json
    unless $config['config']['no_cors']
      headers CORS_HEADERS
    end
  end

  $config['routes'].each_with_index do |rt, i|
    method = nil
    METHODS.each do |m|
      method = m if rt[m]
      break if method
    end
    if method
      send method, $config['config']['namespace'] + rt[method] do
        route = reload_route i
        code = route['status'] || 200
        log code, method.upcase, request.path
        ( route['headers'] || {} ).each do |k, v|
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
  end

  if $config['not_found']
    not_found do
      route = reload_route(-1)
      code = route['status'] || 404
      log code, request.path, ''
      ( route['headers'] || {} ).each do |k, v|
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

  def log( code, method, path )
    print "#{DateTime.now.strftime('%F %T')} - [#{code}] #{method} #{path}\n"
    if $config['config']['verbose']
      if MIME_JSON.include? env['CONTENT_TYPE']
        request.body.rewind
        data = JSON.parse request.body.read
        print "  PARAMS_JSON: #{data.to_s}\n" unless data.empty?
      else
        pars = params.dup
        pars.delete 'captures'
        pars.delete 'splat'
        print "  PARAMS_DATA: #{pars.to_s}\n" if pars.any?
      end
    end
  end

  def interpolate( input )
    vars = input.to_s.scan( /{(.*?)}/ ).flatten.map{|t| eval(t)}
    input.to_s.gsub( /{(.*?)}/, '%s' ) % vars
  end

  def reload_route( route_id )
    config = YAML.load File.read($config_file) || {}
    return config['not_found'] || {} if route_id < 0
    return {} if !config['routes'] || !config['routes'][route_id]
    config['routes'][route_id]
  end

  def traverse!( hash )
    hash.each do |k, v|
      if v.is_a?(Hash) || v.is_a?(Array)
        traverse! v
      else
        hash[k] = interpolate v if v
      end
    end
  end

  run! if app_file == $0 || ENV['http_mock_server_bin']
end
