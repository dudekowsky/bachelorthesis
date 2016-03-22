require_relative "lib/cell"
require_relative "lib/simulation"
require "descriptive_statistics"
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
                                    4, # max_pool_threads
                                    60, # keep_alive_time
                                    TimeUnit::SECONDS,
                                    LinkedBlockingQueue.new)
  num_threads = params[:sims]
  style = params[:style]
  size = params[:size]
  crowder_percentage = params[:crowder_percentage]
  duration = params[:duration]
  stickyness = params[:stickyness]
  ligand_percentage= params[:ligand_percentage]
  enzymatic = params[:place_random]

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
  puts "Size = #{size}^3,#{ligand_percentage}% Ligands #{crowder_percentage}% Crowders, #{stickyness} stickyness, enyzmatic mode: #{enzymatic}"
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
  File.open("./ergebnisse/boundlength-r-#{style}#{size}lig#{ligand_percentage}len#{crowder_percentage}cro#{stickyness}sti#{duration}dur#{enzymatic}enz", 'w') do |file|
    file.write("#style = #{style}, size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness} \n")
    file.write("#max: #{boundlength_arr.max}, min: #{boundlength_arr.min}")
    boundlength_arr.each do |val|
      file.write(val)
      file.write("\n")
    end
  end

  File.open("./ergebnisse/unboundlength-r-#{style}#{size}lig#{ligand_percentage}len#{crowder_percentage}cro#{stickyness}sti#{duration}dur#{enzymatic}enz", 'w') do |file|
    file.write("#style = #{style}, size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness} \n")
    file.write("#max: #{unboundlength_arr.max}, min: #{unboundlength_arr.min}")
    unboundlength_arr.each do |val|
      file.write(val)
      file.write("\n")
    end
  end

  File.open("./ergebnisse/onoffgegenzeit-r-#{style}#{size}lig#{ligand_percentage}len#{crowder_percentage}cro#{stickyness}sti#{duration}dur#{enzymatic}enz", 'w') do |file|
    file.write("#style = #{style}, size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness} \n")
    file.write("#max: #{boundlength_arr.max}, min: #{boundlength_arr.min}")
    steps_array.each_with_index do |val,idx|
      file.write("#{idx}\t#{val}")
      file.write("\n")
    end
  end

  File.open("./ergebnisse/PgegenLmit#{crowder_percentage}C#{size}#{enzymatic}enz#{stickyness}aff","a") do |file|
    file.write("#{ligand_percentage}\t#{mean}\t#{stdDeviation}\n")
  end

end

# File.open("../ergebnisse/averages.data", 'w') do |file|
#   #mean = steps_array.inject{ |sum, el| sum + el }.to_f / steps_array.size
#   file.write("#mean\tcrowder\tsize\tsims\tsim_time\n")
#   #file.write("#{mean}\t#{crowder_percentage}\t#{size}\t#{num_threads}\t#{total_time}\n")
# end
def makefile(params)
  c_arr = params[:crowder_percentages]
  size = params[:size]
  enz = params[:enzymmode]
  sti = params[:stickynesses]
  File.open("makefile", "a") do |f|
  sti.each do |stickyness|
    helptext = ""
    c_arr.each_with_index do |c,ind|
      enz.each do |bool|
          helptext += "'./ergebnisse/PgegenLmit#{c}C#{size}#{bool}enz#{stickyness}aff' with lines title 'C#{c} Aff#{stickyness}'"
          helptext += ", " unless ind - c.size == -1
        end
      end
      text = <<-END
set terminal png
set xlabel 'Ligandenanteil in \\%'
set ylabel "Bindewahrscheinlichkeit"
set output './ergebnisse/PlotPgegenL#{stickyness}aff.png'
plot #{helptext}
      END

      f.write(text)
    end
  end
  puts "makefile created"
end

File.delete("makefile") if File.exist?("makefile")
%x(rm ./ergebnisse/PgegenL*)

startzeit = Time.now
sims = 4
size = 6
duration = 10000
crowder_percentages = [0,10,20,30,40,50,60]
enzymmode = [false]
stickynesses = [60]
[:n].each do |style|
  crowder_percentages.each do |crowder_percentage|
    stickynesses.each do |stickyness|
      [0,3,5,8,10,20].each do |ligand_percentage|
        enzymmode.each do |place_random|
          next if crowder_percentage + ligand_percentage >= 99
          path_to_file = "./ergebnisse/PgegenLmit#{crowder_percentage}C#{size}V#{place_random}enz#{stickyness}aff"
          File.delete(path_to_file) if File.exist?(path_to_file)
          params = {
            sims: sims,
            style: style,
            size: size,
            crowder_percentage: crowder_percentage,
            duration: duration,
            stickyness: stickyness,
            ligand_percentage: ligand_percentage,
            place_random: place_random
          }
          multithread(params)
        end
      end
    end
  end
end
makeparams = {crowder_percentages: crowder_percentages, enzymmode: enzymmode, size: size, stickynesses: stickynesses}
makefile(makeparams)
%x{gnuplot makefile}
puts "Total Completion Time = #{ Time.now - startzeit}"


#sims = number of simulations(good if multiple of cpu cores)
#size = cubic root of volume of cell
#duration = number of steps the system does before ending
#crowder percentage = percentage of crowder particles
#stickyness = inverse probability of particle moving if it is bound.
#explanation: particle moves if dice rolls 1. stickyness is the number of
#sides on dice
#style: 2 possibilities:
# :n means size^3 random grid points are checked in one step
# :all means all size^3 grid points are checked in random order in one step
