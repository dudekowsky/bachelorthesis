
# require 'jruby/profiler'
require_relative "lib/auswertung"
require_relative "lib/cell"
require_relative "lib/simulation"
require "descriptive_statistics"
require 'fileutils'
# used to call java code
require 'java'

# 'java_import' is used to import java classes
java_import 'java.util.concurrent.Callable'
java_import 'java.util.concurrent.FutureTask'
java_import 'java.util.concurrent.LinkedBlockingQueue'
java_import 'java.util.concurrent.ThreadPoolExecutor'
java_import 'java.util.concurrent.TimeUnit'


class SimStarter
  #include Callable
  def initialize(params)

    @params = params
  end
  def call
    sim = Simulation.new(@params)
    return sim.start_with_duration
    # puts "random-" + style.to_s + " simulation:"
    # puts "N = " + n.to_s + ", Size = " + size.to_s + ", Crowder = " + crowder_percentage.to_s + "%"
    # puts "Mittelwert " + (i*1.0 / n).to_s + " steps"
    # print "Simulation took: "
    # print (Time.now - starting_time)
    # puts " seconds to finish"
    # puts " "

  end
end
def theo_prob(att, size, rec_en)

  freevol = size**3 - 7
  (6*Math.exp(rec_en + att)+ freevol*Math.exp(rec_en))/(6*Math.exp(rec_en + att) + freevol*Math.exp(rec_en) + freevol*Math.exp(att) + freevol**2)
end
# sim = SimStarter.new
# sim.call
def multithread(params)
  executor = ThreadPoolExecutor.new(16, # core_pool_treads
                                    16, # max_pool_threads
                                    60, # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)
  num_threads = params[:sims]
  style = params[:style]
  size = params[:size]
  crowder_percentage = params[:crowder_percentage]
  duration = params[:duration]
  receptor_energy = params[:receptor_energy]
  ligand_percentage= params[:ligand_percentage]
  enzymatic = params[:enzymatic]
  attraction = params[:attraction]
  metropolis = params[:metropolis]
  para_string = params[:para_string]

  num_sims = 1
  total_time = 0.0

  result_array = []
  steps_array = []
  energy_array = []
  num_sims.times do |i|
    tasks = []
    t_0 = Time.now

    num_threads.times do
      task = FutureTask.new(SimStarter.new(params))
      executor.execute(task)
      tasks << task
    end

    tasks.each do |t|
      result_array << t.get
    end

    steps_array = result_array.map do |e|
      e[:steps]
    end
    energy_array = result_array.map do |e|
      e[:energy_array]
    end
  t_1 = Time.now

  time_ms = (t_1-t_0) * 1000.0
  # puts "TEST #{i}: Time elapsed = #{time_ms}ms"
  total_time +=  time_ms

  end
  executor.shutdown()
  puts "Random-#{style} Simulation"
  puts "Weak attraction: #{attraction}, Receptor energy: #{receptor_energy}, Metropolis: #{metropolis}"
  puts "Size = #{size}^3, #{ligand_percentage}% Ligands, #{crowder_percentage}% Crowders, enzymatic mode: #{enzymatic}"
  puts "#{num_threads} simulations done. Duration = #{duration} steps"
  p steps_array.map{|subarr| subarr.sum / duration}
  mean = steps_array.map{|subarr| subarr.sum / duration}.mean
  stdDeviation = steps_array.map{|subarr| subarr.sum / duration}.standard_deviation
  steps_array.flatten!
  length = 0
  boundlength_arr = [0]
  unboundlength_arr = [0]
  steps_array.each_with_index do |val,idx|
    if val == 1
      length += 1
      if steps_array[idx + 1] != 1
        boundlength_arr << length
        length = 0
        #p boundlength_arr
      end
    else
      length += 1
      if steps_array[idx + 1] != 0
        unboundlength_arr << length
        length = 0
        # puts length
        # p unboundlength_arr
      end
    end
  end
  energy_array.flatten!(1)

  energy_histogram = energy_array.group_by{|e| e}
  puts "#{boundlength_arr.mean} mean sticky time"
  puts "#{unboundlength_arr.mean} mean unbound time"
  puts "Bound probability #{mean}, Std. Deviation: #{stdDeviation}, relative: #{stdDeviation.to_f/mean}"
  puts "Theoretical probability = #{theo_prob(attraction, size, receptor_energy)}"
  puts "completion time: #{total_time/ 1000 }s"
  para_string = @escaped_para_string % params
  puts para_string

  # File.open("./ergebnisse/boundlength-#{parastring}", 'w') do |file|
  #   file.write("#style = #{style}, size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness}, attraction = #{attraction}\n")
  #   file.write("#max: #{boundlength_arr.max}, min: #{boundlength_arr.min}")
  #   boundlength_arr.each do |val|
  #     file.write(val)
  #     file.write("\n")
  #   end
  # end

  # File.open("./ergebnisse/unboundlength-r-#{para}", 'w') do |file|
  #   file.write("#style = #{style}, size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness}, #{attraction}att \n")
  #   file.write("#max: #{unboundlength_arr.max}, min: #{unboundlength_arr.min}")
  #   unboundlength_arr.each do |val|
  #     file.write(val)
  #     file.write("\n")
  #   end
  # end

  # File.open("./ergebnisse/onoffgegenzeit-r-#{para}", 'w') do |file|
  #   file.write("#style = #{style}, size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness}, #{attraction}att \n")
  #   file.write("#max: #{boundlength_arr.max}, min: #{boundlength_arr.min}")
  #   steps_array.each_with_index do |val,idx|
  #     file.write("#{idx}\t#{val}")
  #     file.write("\n")
  #   end
  # end

  File.open("../ergebnisse/#{para_string}","w") do |file|
    file.write "#P\tstdDeviation\tbound_mean\tunbound_mean\n"
    file.write("#{mean}\t#{stdDeviation}\t#{boundlength_arr.mean}\t#{unboundlength_arr.mean}\n")
  end
  new_energy_histogram = energy_histogram.map{ |key, val| {key => val.count * 1.0 } }
  p new_energy_histogram
  File.open("../ergebnisse/energy#{para_string}","w") do |file|
    new_energy_histogram.each do |entry|
      string = "#{entry.keys.flatten[0]} \t #{entry.keys.flatten[1]} \t #{entry.values[0] * 1.0 / (duration*num_threads)}\n"
      file.write string
    end
  end

end

# File.open("../ergebnisse/averages.data", 'w') do |file|
#   #mean = steps_array.inject{ |sum, el| sum + el }.to_f / steps_array.size
#   file.write("#mean\tcrowder\tsize\tsims\tsim_time\n")
#   #file.write("#{mean}\t#{crowder_percentage}\t#{size}\t#{num_threads}\t#{total_time}\n")
# end


#File.delete("makefile") if File.exist?("makefile")
# %x(rm ./ergebnisse/PgegenL*)

startzeit = Time.now
sims = 16
size = 8
duration = 200000
attractions = [0,0.1,0.3,0.7,1,2,3,10,20]
receptor_energies = [4.0]
crowder_percentages = [5]#[0,1,5,15,30]
ligand_percentages = [0,1,2,4,8,16,32]
enzymmode = [false]
styles = [:n]
metros = [true]
sims_done = 0
total_sims = 1
sammel_arr = [attractions, crowder_percentages,ligand_percentages,enzymmode,receptor_energies,styles,metros]
sammel_arr.each do |par_arr|
  total_sims = par_arr.length * total_sims
end
@escaped_para_string = "%{ligand_percentage}L%{crowder_percentage}C%{size}V%{enzymatic}enz%{receptor_energy}rec_en%{attraction}att%{metropolis}metro"
params_arr = []

styles.each do |style|
  attractions.each do |attraction|
    crowder_percentages.each do |crowder_percentage|
      metros.each do |metropolis|
        receptor_energies.each do |receptor_energy|
          enzymmode.each do |enzymatic|
            ligand_percentages.each do |ligand_percentage|

              params = {
                sims: sims,
                style: style,
                size: size,
                crowder_percentage: crowder_percentage,
                duration: duration,
                receptor_energy: receptor_energy,
                enzymatic: enzymatic,
                attraction: attraction,
                metropolis: metropolis,
                ligand_percentage: ligand_percentage
                #different watch modes cannot go in one pass
              }
              puts "theoretical probability: #{theo_prob(attraction, size, receptor_energy)}"
              para_string = @escaped_para_string % params
              path_to_file = "./ergebnisse/Pmit#{para_string}"
              #File.delete(path_to_file) if File.exist?(path_to_file)
              #next if File.exist?(path_to_file)
              sims_done += 1
              next if crowder_percentage + ligand_percentage >= 90


              # multithread(params)
              params_arr << params
              sims_left = total_sims - sims_done
              time_spent = Time.now - startzeit
              est_finish = Time.now + (time_spent * sims_left / sims_done)
              puts "#{sims_done} of #{total_sims} Sims done"
              puts "Time stamp: #{Time.now}"
              puts "Time spent: #{time_spent}. Estimated finish: #{est_finish}"
              puts "-------------"
            end
          end
        end
      end
    end
  end
end
puts "Total Completion Time = #{ Time.now - startzeit}"
ana = Ana.new(@escaped_para_string)
ana.makegraph(:ligand_percentage, params_arr, [:crowder_percentage, :attraction])

# receptor_energy is in multiples of k*T
# weak attraction is in multiples of k*T
#sims = number of simulations(good if multiple of cpu cores)
#size = cubic root of volume of cell
#duration = number of steps the system does before ending
#crowder percentage = percentage of crowder particles

#style: 2 possibilities:
# :n means size^3 random grid points are checked in one step
# :all means all size^3 grid points are checked in random order in one step
# attraction = E_pot * \beta
