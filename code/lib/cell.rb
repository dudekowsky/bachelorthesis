class Cell
  def initialize(size, target, stickyness)
    @stickyness = stickyness.ceil.abs
    @stickyness = 1 if stickyness == 0
    @size = size
    @grid = generate_grid(@size)
    @target = target
  end

  def generate_grid(size)
    grid = Array.new(size){Array.new(size){Array.new(size){:_}}}
    return grid
  end

  def target_is_found?
    if @grid[@target[0]][@target[1]][@target[2]] == :x
      true
    else
      false
    end
  end

  def get_target
    return @target
  end

  def place_particle(type = :x, tillfoundmode = false, ligand_percentage = 0)
    if ligand_percentage != 0
      ligand_total = (@size ** 3) / 100 * ligand_percentage
    else
      ligand_total = 1
    end
    i = 0
    unless type == :x && !(tillfoundmode)
      while i < ligand_total
        x,y,z = rand(@size),rand(@size),rand(@size)
        if (@grid[x][y][z] == :_) && (@target != [x,y,z])
          @grid[x][y][z] = type
          i+=1
        end
      end
    else
      x,y,z = @target[0],@target[1],@target[2]
      @grid[x][y][z] = type
      return [x,y,z]
    end



  end

  def place_crowder(crowder_percentage)
    crowder_total = (@size ** 3) / 100 * crowder_percentage
    i = 0
    while i < crowder_total
      x,y,z = rand(@size),rand(@size),rand(@size)
      if (@grid[x][y][z] == :_) && (@target != [x,y,z])
        @grid[x][y][z] = :o
        i += 1
      end
    end
    #print_grid
  end

  #decides a random order in which to check all cells
  # and then does the check

  def move_random_all
    #creates an array with 0 - N-1, where N is the size
    # of the cell in 1 dimension. then shuffles.
    # coordinates are codified via
    # x = val % size
    # y = (val / size) % size
    # z = val / size^2
    order_array = (0...(@size**3)).to_a.shuffle
    order_array.each do |val|
      x = val % @size
      y = (val / @size) % @size
      z = val / (@size ** 2)
      type = @grid[x][y][z]
      if (type == :x) || (type == :o)
        if move_particle(x,y,z, @grid, type)
          @grid[x][y][z] = :_
        end
      end
    end
  end

  #makes moves in as many random spots, as there are grid cells
  #may move same grid multiple time,
  #may also not move a grid a time unit
  def move_random_n
    (@size**3).times do
      x,y,z = rand(@size),rand(@size),rand(@size)
      val = @grid[x][y][z]
      if (val == :x) || (val == :o)
        if move_particle(x,y,z,@grid, val)
          @grid[x][y][z] = :_
        end
        #print_grid
      end
    end
  end



  def make_move
    #Method DOES NOT WORK YET!
    #Method can move particle multiple times
    #in 1 timeunit.
    #Also: Need to make order of checking tiles random
    # interesting: in size = 3 grid it takes
    # a mean of 30 with this method.
    # normal is mean of 45
    virtual_grid = generate_grid(@size)
    @grid.each_with_index do |plane, xindex|
      plane.each_with_index do |row, yindex|
        row.each_with_index do |val, zindex|
          if (val == :x) || (val == :o)
            move_particle(xindex,yindex,zindex,virtual_grid, val)
          end
        end
      end
    end
    @grid = virtual_grid
  end

  def move_particle(x,y,z,grid, type)
    if [x,y,z] == @target
      sticky_dice = rand(@stickyness)
      if sticky_dice > 0
        return false
      end
    end
    dice = rand(6)
    case dice
    when 0
      unless illegal?(x,y,((z-1) % @size),type)
        grid[x][y][(z-1) % @size] = type
        return true
      end
    when 1
      unless illegal?(x,y,((z+1) % @size),type)
        grid[x][y][(z+1) % @size] = type
        return true
      end
    when 2
      unless illegal?(x, ((y-1) % @size), z, type)
        grid[x][(y-1) % @size][z] = type
        return true
      end
    when 3
      unless illegal?(x, ((y+1) % @size), z, type)
        grid[x][(y+1) % @size][z] = type
        return true
      end
    when 4
      unless illegal?((x-1) % @size, y, z, type)
        grid[(x-1) % @size][y][z] = type
        return true
      end
    else
      unless illegal?((x+1) % @size, y, z, type)
        grid[(x+1) % @size][y][z] = type
        return true
      end
    end
    return false
  end

  def illegal?(x,y,z,type)
    return true if @grid[x][y][z] != :_
    if (type == :o) &&  (@target == [x,y,z])
      #print_grid
      return true
    else
      return false
    end
  end


  def print_grid
    p @grid
  end
end
