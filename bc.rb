require 'sinatra'
require 'http'
require 'json'
require 'time'
require 'digest'

# a local, port-based blockchain

# reminder to self:
# JSON.dump(test).class == "String"
# JSON.load(str).class == "Hash"

def to_sha(hash)
  # converts a hash to a SHA256
  return Digest::SHA256.hexdigest(JSON.dump(hash))
end

def is_valid?(block)
  return to_sha(block).start_with?('00')
end

def mined(block)
  # tweak block node until block is valid
  until is_valid?(block) do
    block[:nonce] += 1
  end
  return block
end

def block(prev_hash: to_sha(end_of_chain()),
  timestamp: Time.now, payload: "", nonce: 0)
  # generates a block in the form of a hash
  block = {
    timestamp: timestamp,
    prev_hash: prev_hash,
    nonce: nonce,
    payload: payload
  }
  add_block(block)
  return block
end

GEN_BLOCK   = mined(block(prev_hash: "0", timestamp: "0"))
BLOCK_CHAIN = { to_sha(GEN_BLOCK) => GEN_BLOCK }
PEERS       = []
PENDING     = {}

def end_of_chain
  sha = BLOCK_CHAIN.keys[0]
  while true
    found = block_after(sha)
    unless found
      return BLOCK_CHAIN[sha]
    end
    sha = to_sha(found)
  end
end

def block_after(curr_sha)
  return BLOCK_CHAIN.values.detect { |block| block[:prev_hash] == curr_sha }
endjjkk



def sync
  # connect to the sync node and asks for the block_chain
  PEERS.push("5000")
  update = HTTP.get('http://127.0.0.1:5000/sync',
    params: {prev_hash: to_sha(end_of_chain()) })
  BLOCK_CHAIN.merge!(JSON.load(update))
end

def broadcast(params)
  puts params
  PEERS.each do |peer|
    HTTP.put("http://127.0.0.1:#{peer}/add", params: {json: JSON.dump(params)})
  end
end

def find_block(sha)
  puts "searching"
  block = PENDING[sha]
  unless block
    block = BLOCK_CHAIN[sha]
  end
  return block
end

def add_block(block)
  if is_valid?(block)
    puts "ADDED VALID BLOCK #{block}"
    BLOCK_CHAIN[to_sha(block)] = block
  else
    puts "ADDED PENDING BLOCK #{block}"
    PENDING[to_sha(block)] = block
  end
end

def start
  if ARGV[0] == "5000"
    # Test if /sync is working
    prev = to_sha(GEN_BLOCK)

    10.times do
      b = block(prev_hash: prev)
      #b = mined(b)
      puts "BLOCK: #{b}"
      prev = to_sha(b)
      PENDING[prev] = b
    end
    else
      puts "synchronising..."
      start = Time.now
      sync()
      puts "downloaded chain. It took #{Time.now - start} second(s)"
  end
end

set :port, ARGV[0]

get '/sync' do
  content_type :json
  # supplement getter node its blocks based on the given last_block of that getter
  resp      = {}
  last_sha  = params['prev_hash']

  while true
    found = block_after(last_sha)
    unless found
      return JSON.dump(resp)
    end
    resp[last_sha] = found
    last_sha = to_sha(found)
  end
end

get '/chain' do
  return erb :chain,
   locals: { blocks: BLOCK_CHAIN }
 end

get '/pending' do
  return erb :pending,
   locals: { blocks: PENDING }
end

get '/block' do
  block = find_block(params["sha"])
  unless block
    block = block()
  end
  return erb :block, locals: { block: block }
end

post '/block' do
  add_block(find_block(params["sha"]))
  redirect "/block?sha=#{params["sha"]}"
end

post '/block/mine' do
  block = find_block(params["sha"])
  puts "BLOCK #{block}"
  unless block
    "Could not find a block with that hash-code."
  end
  mined_block = mined(block)
  BLOCK_CHAIN[to_sha(mined_block)] = mined_block
  PENDING.delete(params["sha"])
  redirect "/block?sha=#{to_sha(mined_block)}"
end

start()
