class Simulation
  def initialize(size = 10, crowder_percentage = 0, stickyness = 10, duration = 300000, tillfoundmode = false)
    @duration = duration
    target = [rand(size),rand(size),rand(size)]
    @cell = Cell.new(size, target, stickyness)
    #puts "Starting point is:"
    @cell.place_particle(:x, tillfoundmode)
    @cell.place_crowder(crowder_percentage)
  end

  def start(mode = :n)
    #print_target_coordinates
    #print_cell
    steps = 0
    # puts steps
    # p @cell.get_target
    until target_is_found?
      steps += 1
      # puts target_is_found?
      #print_cell
      move_random_n if mode == :n
      move_random_all if mode == :all
    end
    #print_cell
    #puts "It took " + steps.to_s + " steps to find its mark"
    return steps
  end

  def start_with_duration(mode = :n)
    # array for statistic analysis later on.
    # add 1 when bound and 0 when not bound

    bound_arr = []
    steps = 0
    bound_time = 0
    if mode == :n
      while steps < @duration do
        move_random_n
        if target_is_found?
          bound_arr << 1
        else
          bound_arr << 0
        end
        steps += 1
        #puts "steps: #{steps}"
      end
    end
    if mode == :all
      while steps < @duration do
        move_random_all
        if target_is_found?
          bound_arr << 1
        else
          bound_arr << 0
        end
        steps += 1
        #puts "steps: #{steps}"
      end
    end
    # puts "Bound steps: #{bound_time}"
    # puts "Total steps: #{steps}"
    # puts "Ratio: #{bound_time.to_f/steps}"
    return bound_arr
  end

  def target_is_found?
    @cell.target_is_found?
  end

  def move_random_all
    @cell.move_random_all
  end

  def move_random_n
    @cell.move_random_n
  end

  def print_target_coordinates
    puts "Target is: "
    p @cell.get_target
  end

  def make_move
    @cell.make_move
  end

  def print_cell
    @cell.print_grid
  end

end
