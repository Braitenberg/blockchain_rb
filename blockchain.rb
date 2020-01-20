require 'sinatra'
require 'http'
require 'json'
require 'time'
require 'digest/md5'

NEIGHBOURS = {}
BLOCKCHAIN = {}
PENDING_BLOCKS = []
PREVIOUS_HASH = "0"
VALID_HASH = '00'

# Define a startpoint for peer discovery
NEIGHBOURS["127.0.0.1:5000"] = true

port_param = ARGV[0]

class Block
  def initialize(options={nonce: 0, timestamp: Time.now})
    @json = {block: options}
    @nonce = options[:nonce]
    @timestamp = options[:timestamp]
    @previous_hash = options[:previous_hash]
    @data = options[:data]
  end

  def as_json
    return @json
  end

  def is_valid?
    return self.hashed.start_with?(VALID_HASH)
  end

  def hashed
    block_string = self.sort.to_h.to_json.encode
    Digest::MD5.hexdigest(block_string)
  end
end


class Transactor
  # send() and receive() should complement each other
  def send(params, port)
    NEIGHBOURS.keys.each do |adress|
      HTTP.put(
        "http://#{adress}/transaction",
        body: {block: params[:block], port: port}.to_json
      )
    end
    puts " * Sent block #{params[:block]}"
  end

  def receive(request)
    puts " * Received #{request}"

    request.body.rewind
    NEIGHBOURS[request.ip + JSON.parse(request.body.read)["port"]] = true

    request.body.rewind
    block = Block.new(JSON.parse(request.body.read)["block"])
    if block.is_valid?
      BLOCKCHAIN[block.hashed] = block
    else
      PENDING_BLOCKS.push(block)
    end
  end
end

set :port, port_param
set :logging, :true

get '/' do
  content_type :json
  return JSON(BLOCKCHAIN)
end

transaction = Transactor.new

put '/transaction' do
  transaction.receive(request)
end

get '/transaction/new' do
 # TODO: return a form that calls GET /transaction
 # shows pending blocks too
 return erb :transaction_new, locals: {
   pending: PENDING_BLOCKS
 }
end

get '/transaction' do
  params =
  {
    block: {
      previous_hash: PREVIOUS_HASH,
      data: "spanish inquisition"
    }
  }

  transaction.send(params, port_param.to_str)
  return '<img src="https://i0.kym-cdn.com/photos/images/facebook/001/170/001/c44.png" height=300>'
end
