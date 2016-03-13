require_relative "lib/cell"
require_relative "lib/simulation"
require "descriptive_statistics"

start_time_total = Time.now
crowder_percentages = [20,30,50,60,80]
crowder_percentages.each do |crowder_percentage|
  size = 8
  stickyness = 100
  duration = 0
  arr =[]
  start_time = Time.now
  n = 10000
  n.times do |iteration|
    sim = Simulation.new(size, crowder_percentage, stickyness, duration, true)
    arr << sim.start
    running_time = Time.now - start_time
    puts "estimated finish = #{Time.now + (n * 1.0 / (iteration*1.0 + 0.001 ) * running_time)- running_time}"
  end



  File.open("./ergebnisse/untilfound/untilfound-#{size}lengthunits#{crowder_percentage}crowderpercent#{n}repetitions", 'w') do |file|
    file.write("size = #{size}, crowder percentage = #{crowder_percentage}, stickyness = #{stickyness} \n")
    arr.each do |val|
      file.write(val)
      file.write("\n")
    end
  end
end
total_seconds = Time.now - start_time_total
seconds = total_seconds % 60
minutes = (total_seconds / 60) % 60
hours = total_seconds / (60 * 60)
puts "total time:"
puts format("%02d:%02d:%02d", hours, minutes, seconds)
