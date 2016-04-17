class Cell
  def initialize(params)
    params.each do |key, val|
      instance_variable_set "@#{key}", val
    end
    @reaction_time ||= Math.exp(@receptor_energy).ceil
    @forbid_reaction_stop ||= true
    @forbid_reaction_stop = false unless @enzymatic

    @grid = generate_grid(@size)
    @count = 0
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

  def place_particle(type = :x, enzymatic = false, ligand_percentage = 0)
    if ligand_percentage != 0
      ligand_total = (@size ** 3) / 100 * ligand_percentage
    else
      ligand_total = 1
    end
    i = 0
    unless type == :x && !(enzymatic)
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

    crowder_total = (@size ** 3)*1.0 / 100 * crowder_percentage
    #puts "crowder_total = #{crowder_total}"
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

  # def move_random_all
  #   #creates an array with 0 - N-1, where N is the size
  #   # of the cell in 1 dimension. then shuffles.
  #   # coordinates are codified via
  #   # x = val % size
  #   # y = (val / size) % size
  #   # z = val / size^2
  #   order_array = (0...(@size**3)).to_a.shuffle
  #   order_array.each do |val|
  #     x = val % @size
  #     y = (val / @size) % @size
  #     z = val / (@size ** 2)
  #     type = access([x,y,z])
  #     if (type == :x) || (type == :o)
  #       if move_particle(x,y,z, type)
  #         set([x,y,z],:_)
  #       end
  #     end
  #   end
  # end

  #makes moves in as many random spots, as there are grid cells
  #may move same grid multiple time,
  #may also not move a grid a time unit
  def move_random_n
    (@size**3).times do
      x,y,z = rand(@size),rand(@size),rand(@size)
      val = access([x,y,z])
      next if @forbid_reaction_stop && ([x,y,z] == @target)

      if (val == :x) || (val == :o)
        if move_particle(x,y,z, val)
          set([x,y,z],:_)
        end
      end
    end
    reacts? if target_is_found?
    #puts @ligand_energy
    if @count > 1
      puts "#{@count} count"
      print_grid
    end
    [@count, target_is_found?]
  end

  def reacts?
    return false unless @enzymatic
    if rand(@reaction_time) == 0
      place_particle(:x, true)
      free_target
    end
  end

  def access(arr)
    size = @size
    return @grid[arr[0] % size][arr[1] % size][arr[2] % size]
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
  # the move and calculating the probability by
  # exp(-N*att)
  def rec_energy(pos)
    return @receptor_energy if pos == @target
    return 0
  end
  ###
  # calculates energy before and after move and
  # calculates true or false, based if
  # random number between 0 and 1 is bigg
  def held_by_attraction?(before,after, type)
    #false unless access(before) == :x
    if @metropolis == true
      count_before = count_after = 0

      if @attraction > 0
        # puts "hey im counting!"
        count_before = count(before)
        count_after = count(after)
      end
      e_before = count_before*@attraction + rec_energy(before)
      e_after = count_after*@attraction + rec_energy(after)
      if (prob(e_before, e_after) < rand)
        (@count = count_before) if type == :x
        true
      else
        (@count = count_after) if type == :x
        false
      end

    else
      puts "NOT IMPLEMENTED YET"
      # count_before = count(before)
      # e_before = count_before*@attraction + rec_energy(before)
      # if (prob(e_before) < rand)
      #   @ligand_energy = e_before if type == :x
      #   true
      # else
      #   @ligand_energy = e_after if type == :x
      #   false
      # end
    end
  end

  def prob(before, after = 0)
    Math.exp(-(before - after))
  end

  def count(coordinates)
    arr = []
    [-1,1].each do |number|
      arr << access([coordinates[0] + number, coordinates[1], coordinates[2]])
      arr << access( [coordinates[0], coordinates[1] + number, coordinates[2]])
      arr << access( [coordinates[0], coordinates[1], coordinates[2] + number])
    end
    arr.count{|e| e == :o}
  end

  def move_particle(x,y,z, type)
    before = [x,y,z]
    after = next_field(before)
    return false if illegal?(after,type)
    if type == :x
      return false if held_by_attraction?(before, after,type)
    end
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
    puts "Target is: #{@target}"
    puts "And it is occupied" if target_is_found?
    p @grid
  end
end
