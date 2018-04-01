require 'pry'
require 'sinatra/base'
require 'yaml'

CONFIG_FILE = 'mock.yml'
MIME_JSON = ['application/json']

$config = YAML.load File.read(CONFIG_FILE) rescue begin
    puts "Config file not found: #{CONFIG_FILE}"
    exit 1
  end
$config['config'] ||= {}
$config['routes'] ||= []

class HttpMockServer < Sinatra::Base
  METHODS = %w(connect delete get head options patch post put trace)

  # set :environment, :development
  set :port, $config['config']['port'] if $config['config']['port']
  set :server_settings, timeout: $config['config']['timeout'] || 0

  configure do
  end

  before do
    content_type :json
    unless $config['config']['no_cors']
      headers(
        'Access-Control-Allow-Origin'  => '*',
        'Access-Control-Allow-Methods' => 'POST, GET, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers' => 'Origin, Content-Type, Accept, Authorization, Token',
      )
    end
  end

  $config['routes'].each_with_index do |rt, i|
    method = nil
    METHODS.each do |m|
      method = m if rt[m]
      break if method
    end
    if method
      send method, rt[method] do
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

  def interpolate( string )
    return '' unless string
    vars = string.scan( /{(.*?)}/ ).flatten.map{|t| eval(t)}
    string.gsub( /{(.*?)}/, '%s' ) % vars
  end

  def reload_route( route_id )
    config = YAML.load File.read(CONFIG_FILE) || {}
    return config['not_found'] || {} if route_id < 0
    return {} if !config['routes'] || !config['routes'][route_id]
    config['routes'][route_id]
  end

  def traverse!( hash )
    hash.each do |k, v|
      if v.is_a?(Hash)
        traverse! v
      else
        hash[k] = interpolate v
      end
    end
  end

  run! if app_file == $0 || ENV['http_mock_server_bin']
end
