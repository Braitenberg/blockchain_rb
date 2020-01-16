require 'time'
require 'digest/sha1'

class Block

  @@valid_hash_startswith = '00'

  def initialize(previous_hash, data)
    @nonce = 0
    @timestamp = Time.now
    @previous_hash = previous_hash
    @data = data
  end

  def json
    return {
      timestamp: @timestamp.to_s,
      nonce: @nonce,
      previous_hash: @previous_hash,
      data: @data
    }
  end

  def hashed
    full_string = @nonce.to_s + @previous_hash + @data + @timestamp.to_f.to_s
    return Digest::SHA1.hexdigest(full_string)
  end

  def proof
    # generate a Proof of Work (PoW) with a nonce
    puts " * Generating PoW"
    start = Time.now

    while true
      cur_hash = self.hashed
      puts " * current hash: #{cur_hash}, nonce: #{@nonce}"
      is_valid = cur_hash.start_with?(@@valid_hash_startswith)

      if is_valid
        puts " * valid nonce found! It took #{Time.now - start} second(s)"
        break
      else
        @nonce += 1
      end
    end
  end

end
