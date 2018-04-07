require File.expand_path '../spec_helper.rb', __FILE__

RSpec.describe HttpMockServer do
  it 'returns not found' do
    get '/'
    conf = $config['not_found']
    expect(last_response.body).to eq conf['body'].to_json
    expect(last_response.status).to eq 404
    unless $config['config']['no_cors']
      expect(HttpMockServer::CORS_HEADERS.to_a - last_response.headers.to_a).to be_empty
    end
  end

  it 'returns the list of posts' do
    get '/api/v1/posts'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ message: 'List of posts' }.to_json)
  end

  it 'returns a post' do
    get '/api/v1/posts/1'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ post: 'Post #1' }.to_json)
  end

  it 'returns another post' do
    get '/api/v1/posts/123'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ post: 'Post #123' }.to_json)
  end

  it 'creates a post' do
    post '/api/v1/posts'
    expect(last_response.status).to eq 201
    expect(last_response.body).to eq({ code: '201', result: 'Ok' }.to_json)
  end

  it 'deletes something' do
    delete '/api/v1/something'
    expect(last_response.status).to eq 405
    expect(last_response.body).to eq({ message: 'Please don\'t do it' }.to_json)
  end
end
