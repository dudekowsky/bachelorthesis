class Simulation
  def initialize(params)
    size = params[:size] || 5
    crowder_percentage = params[:crowder_percentage] || 0
    stickyness = params[:stickyness] || 1
    @stickyness = stickyness
    duration = params[:duration] || 10000
    tillfoundmode = params[:place_random] || true
    ligand_percentage = params[:ligand_percentage] || 0
    @enzymatic = tillfoundmode
    @duration = duration
    target = [rand(size),rand(size),rand(size)]
    @cell = Cell.new(size, target, stickyness)
    @cell.place_particle(:x, tillfoundmode, ligand_percentage)
    @cell.place_crowder(crowder_percentage)
  end

  def start(mode = :n)
    steps = 0
    until target_is_found?
      steps += 1
      move_random_n if mode == :n
      move_random_all if mode == :all
    end
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
      end
    end
    if mode == :all
      while steps < @duration do
        move_random_all
        if target_is_found?
          if @enzymatic && reacts?
            @cell.place_particle(:x, true)
            free_target
          end
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

  def reacts?
    return true if rand(@stickyness) == 0
    return false
  end

  def free_target
    @cell.free_target
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
