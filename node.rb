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

  def tell(message)
    if message[:adress]
      @grid.join(message[:adress])
    end
    # TODO: add block message
  end

  def add_block(block)
    self.pulse({block: block.json})
    @chain[block.hash] = block
  end
end
