class Grid

  def initialize
    @members = []
    @pending = []
    @chain = {}
  end

  def connect(ip)
    startpoint='127.0.0.1:5000'
    if not ip.equals(startpoint)
      response = http.get "http://#{startpoint}/sync"
      @members = response[:nodes]
    end
  end

  def tell(event)
    @members.map { |member| http.put "http://#{member}/sync?data=#{event}" }
  end

  def get_chain_json
    # TODO: make this a hash comprehension
    json = {}
    @chain.each do |hash, block|
       json[hash] = block.json
    end
    return json
  end

end
