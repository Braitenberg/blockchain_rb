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

get '/sync' do
  data = params[:data]
  if not data
      data = { adress: request.ip }
  end

  node.sync(data)
  return JSON node.data
end

get '/update' do
  # TODO: return a list of potential storylines that then can
  # be accepted or denied by the user
  node.pending
end

put '/update' do
  node.accept(params[block_hash])
end

put '/generate' do
  # generate a block
end
