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

# sim = SimStarter.new
# sim.call
def multithread(params)
  executor = ThreadPoolExecutor.new(4, # core_pool_treads
                                    8, # max_pool_threads
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

  steps_array = []

  num_sims.times do |i|
    tasks = []
    t_0 = Time.now

    num_threads.times do
      task = FutureTask.new(SimStarter.new(params))
      executor.execute(task)
      tasks << task
    end

    tasks.each do |t|
      steps_array << t.get
    end
  t_1 = Time.now

  time_ms = (t_1-t_0) * 1000.0
  # puts "TEST #{i}: Time elapsed = #{time_ms}ms"
  total_time +=  time_ms

  end
  executor.shutdown()
  puts "Random-#{style} Simulation"
  puts "Weak attraction = #{attraction}, #{receptor_energy} receptor_energy, Metropolis: #{metropolis}"
  puts "Size = #{size}^3,#{ligand_percentage}% Ligands #{crowder_percentage}% Crowders, enzymatic mode: #{enzymatic}"
  puts "#{num_threads} simulations done. Duration = #{duration} steps"
  p steps_array.map{|subarr| subarr.sum / duration}
  mean = steps_array.map{|subarr| subarr.sum / duration}.mean
  stdDeviation = steps_array.map{|subarr| subarr.sum / duration}.standard_deviation
  steps_array.flatten!
  length = 0
  boundlength_arr = []
  unboundlength_arr = []
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



  puts "#{boundlength_arr.mean} mean sticky time"
  puts "#{unboundlength_arr.mean} mean unbound time"
  puts "Bound probability #{mean}, Std. Deviation: #{stdDeviation}, relative: #{stdDeviation.to_f/mean}"
  puts "completion time: #{total_time/ 1000 }s"
  puts "-------------"
  para_string = "#{crowder_percentage}C#{size}V#{enzymatic}enz#{receptor_energy}rec_en#{attraction}att#{metropolis}metro"
  # File.open("./ergebnisse/boundlength-#{para}", 'w') do |file|
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

  File.open("./ergebnisse/PgegenLmit#{para_string}","a") do |file|
    file.write("#{ligand_percentage}\t#{mean}\t#{stdDeviation}\n")
  end

end

# File.open("../ergebnisse/averages.data", 'w') do |file|
#   #mean = steps_array.inject{ |sum, el| sum + el }.to_f / steps_array.size
#   file.write("#mean\tcrowder\tsize\tsims\tsim_time\n")
#   #file.write("#{mean}\t#{crowder_percentage}\t#{size}\t#{num_threads}\t#{total_time}\n")
# end
def makefile(params_arr,escaped_para_string, group_para)
  params_arr.each{|param| param.delete(:ligand_percentage)}
  params_arr.uniq!
  File.open("makefile#{group_para}", "w+") do |f|
    escaped_legend_string = "C%{crowder_percentage} E_rec%{receptor_energy} Att%{attraction} Enz%{enzymatic} Metro%{metropolis}"
    params_grouped = params_arr.group_by{ |hash| hash[group_para]}
    puts "grouped params:"
    p params_grouped
    params_grouped.each do |key, para_set|
      puts "para set:"
      p para_set
      para_set_size = para_set.size
      puts para_set_size
      helptext = ""
      para_set.each_with_index do |para_hash, idx|
        legend_string = escaped_legend_string % para_hash
        para_string = escaped_para_string % para_hash
        helptext += "'./ergebnisse/PgegenLmit#{para_string}' with lines title '#{legend_string}'"
        puts "index: #{idx + 1}"
        helptext += ", " unless (idx + 1) == para_set_size
      end
      text = <<-END
set terminal png
set xlabel 'Ligandenanteil in \\%'
set ylabel "Bindewahrscheinlichkeit"
set output './ergebnisse/PlotPgegenL#{key}#{group_para}.png'
plot #{helptext}
      END

      f.write(text)
    end
  end
  puts "makefile#{group_para} created"
end

#File.delete("makefile") if File.exist?("makefile")
# %x(rm ./ergebnisse/PgegenL*)

startzeit = Time.now
sims = 8
size = 10
duration = 30000
attractions = [0]
crowder_percentages = [30]
ligand_percentages = [1,2,3,5,6,8,12]
enzymmode = [true]
receptor_energies = [2,3,4]
styles = [:n]
metros = [true]
sims_done = 0
total_sims = 1
[attractions, crowder_percentages,ligand_percentages,enzymmode,receptor_energies,styles,metros].each do |par_arr|
  total_sims = par_arr.length * total_sims
end
escaped_para_string = "%{crowder_percentage}C%{size}V%{enzymatic}enz%{receptor_energy}rec_en%{attraction}att%{metropolis}metro"
params_arr = []

FileUtils.mkdir_p 'ergebnisse'
styles.each do |style|
  attractions.each do |attraction|
    crowder_percentages.each do |crowder_percentage|
      metros.each do |metropolis|
        receptor_energies.each do |receptor_energy|
          enzymmode.each do |enzymatic|

            params = {
              sims: sims,
              style: style,
              size: size,
              crowder_percentage: crowder_percentage,
              duration: duration,
              receptor_energy: receptor_energy,
              enzymatic: enzymatic,
              attraction: attraction,
              metropolis: metropolis
            }
            para_string = escaped_para_string % params
            params[:para_string] = para_string
            path_to_file = "./ergebnisse/PgegenLmit#{para_string}"
            File.delete(path_to_file) if File.exist?(path_to_file)
            #next if File.exist?(path_to_file)
            ligand_percentages.each do |ligand_percentage|
              sims_done += 1
              next if crowder_percentage + ligand_percentage >= 90
              params[:ligand_percentage] = ligand_percentage
              puts escaped_para_string % params
              multithread(params)
              params_arr << params
              sims_left = total_sims - sims_done
              time_spent = Time.now - startzeit
              est_finish = Time.now + (time_spent * sims_left / sims_done)
              puts "#{sims_done} of #{total_sims} Sims done"
              puts "Time spent: #{time_spent}. Estimated finish: #{est_finish}"
            end
          end
        end
      end
    end
  end
end
group_para = :receptor_energy
makefile(params_arr, escaped_para_string, group_para)
%x{gnuplot makefile#{group_para}}
puts "Total Completion Time = #{ Time.now - startzeit}"

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
