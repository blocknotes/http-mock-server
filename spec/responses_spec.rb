require File.expand_path '../spec_helper.rb', __FILE__

RSpec.describe HttpMockServer do
  it 'returns not found' do
    get '/'
    conf = $config['not_found']
    expect(last_response.body).to eq conf['body'].to_json
    expect(last_response.status).to eq (conf['status'] || 404)
    unless $config['config']['no_cors']
      expect(HttpMockServer::CORS_HEADERS.to_a - last_response.headers.to_a).to be_empty
    end
  end

  it 'returns a message' do
    get '/api/v1/posts'
    expect(last_response.body).to eq({ message: 'List of posts' }.to_json)
  end
end
