require 'sinatra'

require_relative 'node'

# The listener is just a web-server that "listens" for
# http-requests of participants and controls data-exchange
# with them

set :port, 5000
set :logging, :true

node = Node.new

get '/' do
  content_type :json
  JSON node.start
end

put '/sync' do
  if not params['data']
      params['data'] = { 'ip': request.ip }
  end

  node.sync(data)

  return JSON node.data
end

get '/update' do
  node.pending
end

put '/update' do
  node.proof_all(params['pending'])
end

put '/generate' do
  # generate a block
end
