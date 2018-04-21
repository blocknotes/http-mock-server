require File.expand_path '../spec_helper.rb', __FILE__

RSpec.describe HttpMockServer do
  it 'returns the authors' do
    get '/api/v1/authors'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ path: '/api/v1/authors' }.to_json)
  end

  it 'returns an author' do
    id = rand 100
    get "/api/v1/authors/#{id}"
    expect(last_response.status).to eq 200
    json = JSON.parse last_response.body
    expect(json['var']).to eq(id.to_s)
    expect(json['hash']).to eq('key1' => 'Just a key 4')
    expect(json['array']).to eq([{ 'name' => 'Item 2' }, { 'name' => 'Item 4' }, { 'name' => 'Item 6' }])
  end
end
