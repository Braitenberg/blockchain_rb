require 'http'

require_relative 'block'
require_relative 'grid'

class Node
  # a node represents a user that can transact, verify and accept blocks
  # and holds a copy of the blockchain

  # TODO: add a grid object that represents the grid

  def initialize(port="5000")
    @port = port
    @grid = Grid.new
  end

  def start
    # join node to the grid via the startpoint
    print " * starting node #{@port}..."
    @grid.connect(self)
  end

  def sync(event)
    # TODO: clean this function up, it is a mess
    # tri: perhaps i should add a "update()" which return accepted
    forward = false

    data.keys.each do |key|
      key.downcase

      if key == :ip
        if @nodes.include? data[:ip]
          @nodes.push data[:ip]
          accepted = true
        end
      elsif key == :block
        adress = data[:block][:hash]

        if not peding.include? adress or not chain.include? adress
          accepted = true
        end
      end
    end

    if accepted
      return @grid.tell(event)
    end
  end

  def update(key, value)
    if key.equals(:ip)
      if
      @grid.join(value[:ip])
    if key.equals(:block)
      adress = data[:block][:hash]
      if not pending.include?(adress)


    def proof_all
      @grid.pending.each do |json|
        block = Block.new(json[:previous_hash], json[:data])
        block.proof
        self.add_block block
    end
  end

  def add_block(block)
    self.pulse({block: block.json})
    @chain[block.hash] = block
  end
end
