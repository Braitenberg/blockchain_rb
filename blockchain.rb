require 'sinatra'
require 'http'
require 'json'
require 'time'
require 'digest/md5'

VALID_START = '00'

class Block

  attr_accessor :previous_hash
  attr_accessor :data

  def initialize(previous_hash, data, nonce=0, timestamp=Time.now)
    @nonce = nonce.to_i
    @timestamp = timestamp
    @previous_hash = previous_hash
    @data = data
  end

  def from_json(json)
    return self.new(
      previous_hash: json["previous_hash"],
      data: json["data"],
      nonce: json["nonce"],
      timestamp: json["timestamp"]
    )
  end

  def to_json
    return {
      "previous_hash": @previous_hash,
      "data": @data,
      "nonce": @nonce,
      "timestamp": @timestamp
    }
  end

  def mine
    until self.is_valid? do
      puts "MINE"
      @nonce += 1
    end
    return self
  end

  def is_valid?
    return self.hashed.start_with?(VALID_START)
  end

  def hashed
    block_string = self.to_json.to_s
    Digest::MD5.hexdigest(block_string)
  end
end

def find_last_block(chain)
  chain.keys.each do |hash|
    chain.values.each do |block|
      if block.previous_hash == hash
        break
      end
    end
    return chain[hash]
  end
end

NEIGHBOURS = {}
BLOCKCHAIN = {"0":Block.new("0", "")}
PENDING_BLOCKS = []

port_param = ARGV[0]

# Define a startpoint for peer discovery
unless port_param == "5000"
  NEIGHBOURS["127.0.0.1"] = "5000"
end

def tell_all(params, except)
  NEIGHBOURS.each do |ip, port|
    puts except, +" #{ip}:#{port}"
    unless "#{ip}:#{port}" == except
      puts "NOT EQUAL"
      HTTP.post("http://#{ip}:#{port}/transaction", form: params)
    end
  end
end

set :port, port_param
set :logging, :true

get '/' do
  content_type :json
  return JSON(BLOCKCHAIN)
end

post '/transaction/mine' do
  mined = PENDING_BLOCKS[params[:block_index].to_i].mine
  BLOCKCHAIN[mined.hashed] = mined

  json = mined.to_json

  tell_all(mined.to_json, "#{request.ip}:#{params["port"]}")

  PENDING_BLOCKS.delete_at(params[:block_index])
  redirect '/transaction'
end

post '/transaction' do
  puts " * Received #{params}"


  tell_all(params, "#{request.ip}:#{params["port"]}")

  block = Block.new(params["previous_hash"], params["sentence"], params["nonce"])

  if block.is_valid?
    BLOCKCHAIN[block.hashed] = block
  else
    puts "added #{block}"
    PENDING_BLOCKS.push(block)
  end

  redirect '/transaction'

end

get '/transaction' do
 # TODO: return a form that calls GET /transaction
 # shows pending blocks too
 return erb :transaction_new, locals: {
   port_param: port_param,
   pending: PENDING_BLOCKS,
   last_block: find_last_block(BLOCKCHAIN)
 }
end
