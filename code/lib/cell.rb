class Cell
  def initialize(size, target, stickyness, attraction)
    @stickyness = stickyness.ceil.abs
    @stickyness = 1 if stickyness == 0
    @size = size
    @grid = generate_grid(@size)
    @target = target
    @attraction = attraction
  end

  def generate_grid(size)
    grid = Array.new(size){Array.new(size){Array.new(size){:_}}}
    return grid
  end

  def target_is_found?
    if access(@target) == :x
      true
    else
      false
    end
  end

  def get_target
    return @target
  end

  def free_target
    set @target, :_
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
        if (access([x,y,z]) == :_) && (@target != [x,y,z])
          set([x,y,z],type)
          i+=1
        end
      end
    else
      set @target,type
      return [x,y,z]
    end



  end

  def place_crowder(crowder_percentage)
    crowder_total = (@size ** 3) / 100 * crowder_percentage
    i = 0
    while i < crowder_total
      x,y,z = rand(@size),rand(@size),rand(@size)
      if (access([x,y,z]) == :_) && (@target != [x,y,z])
        set([x,y,z],:o)
        i += 1
      end
    end
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
      type = access([x,y,z])
      if (type == :x) || (type == :o)
        if move_particle(x,y,z, @grid, type)
          set([x,y,z],:_)
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
      val = access([x,y,z])
      if (val == :x) || (val == :o)
        if move_particle(x,y,z,@grid, val)
          set([x,y,z],:_)
        end
      end
    end
  end

  def access(arr)
    return @grid[arr[0]][arr[1]][arr[2]]
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

  #has 2 possibilities:
  # a)Metropolis-rate and b)simple detachment rate
  # for a) it checks energy before and after the move.
  # energy checking is done by counting surrounding particles
  # before and after the move
  # probability of moving is then exp( -delta_N * att)
  # with delta_E = N_before - N_after and att = E_0/(kB*T)
  # with E_0 being the weak attraction potential of a single
  # crowder
  # b) works by just checking the number of particles before
  # the move and calculating the propbability by
  # exp(-N*att)
  def held_by_weak_attraction?(before,after)
    false unless access(before) == :x
    if @metropolis == true
      count_before = count(before)
      count_after = count(after)
      return (prop(count_before, count_after) < rand)
    else
      count_before = count(before)
      bool = (prop(count_before) < rand)
      return bool
    end
  end

  def prop(before, after = 0)
    Math.exp(-(before - after)*@attraction)
  end

  def count(coordinates)
    arr = []
    particles = 0
    coordinates.each do |dim|
      arr << ((dim + 1) % @size)
      arr << ((dim - 1) % @size)
    end
    arr.each do |coord|
      particles += 1 if access(coord) != :_
    end
    particles
  end

  def move_particle(x,y,z,grid, type)
    before = [x,y,z]
    if before == @target
      sticky_dice = rand(@stickyness)
      if sticky_dice > 0
        return false
      end
    end
    after = next_field(before)
    return false if illegal?(after,type)
    return false if (@attraction > 0) && held_by_weak_attraction?(before, after)
    set(after, type)
    return true
  end

  def set(co, type)
    @grid[co[0]][co[1]][co[2]] = type
  end

  def next_field(before)
    after = [0,0,0]
    (0..2).each do |i|
      after[i] = before[i]
    end
    dice = rand(6)

    case dice
    when 0
      after[2] = (after[2] - 1) % @size
    when 1
      after[2] = (after[2] + 1) % @size
    when 2
      after[1] = (after[1] - 1) % @size
    when 3
      after[1] = (after[1] + 1) % @size
    when 4
      after[0] = (after[0] - 1) % @size
    else
      after[0] = (after[0] + 1) % @size
    end

    after
  end

  def illegal?(coords,type)
    return true if access(coords) != :_
    if (type == :o) &&  (@target == coords)
      return true
    else
      return false
    end
  end


  def print_grid
    p @grid
  end
end
