require "descriptive_statistics"


File.delete "makefile"
files =[]
times = [20,30,50,60,80]
position = 0
times.each do |crowder|
 files << "untilfound-8lengthunits#{crowder}crowderpercent10000repetitions"
end



files.each do |filename|
  content = File.readlines(filename)
  arr = []
  content.each do |line|
    arr << line.to_i
  end
  arr.sort!
  counts = Hash.new 0
  (1..arr[-1]).each do |val|
    counts[val] = 0
  end
  arr.each do |time|
    counts[time] += 1
  end
  File.open("histo#{filename}", "w") do |f|
    counts.each do |t, frequency|
      f.write("#{t}\t#{frequency}\n") unless t == 0
    end
  end
  crowder = times[position]
  position += 1
  File.open("makefile", "a") do |f|
    text = <<-END
f#{crowder}(x) = b#{crowder}*exp(-a#{crowder}*x )
b#{crowder} = 150
a#{crowder} = 0.001
fit f#{crowder}(x) "histo#{filename}" u 1:2 via a#{crowder},b#{crowder}
set xlabel "t in s"
set ylabel "Frequenz"
set xrange [0:5000]
set terminal png
set output "plot#{filename}.png"
plot "histo#{filename}" u 1:2 title "Datenpunkt", f#{crowder}(x) title gprintf("exp(%f * x)",a#{crowder})
END
    f.write text
  end
end
plotfunc_string = ""
times.each do |val|
  plotfunc_string += "f#{val}(x) title sprintf('f#{val} = %f * exp(%f * x)',b#{val},a#{val})"
  plotfunc_string += ", " unless val == 80
end
File.open("makefile", "a") do |f|
  text = <<-END
set output "comparison.png"
plot #{plotfunc_string}
reset
  END
  f.write text
end

%x(gnuplot makefile)
