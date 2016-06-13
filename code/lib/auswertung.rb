class Hash
  def to_readable
    output = ""
    self.each do |key,val|
      output << "#{key}#{val}"
    end
    output
  end
end
class Array
  def to_readable
    output = ""
    self.each do |entry|
      output << "#{entry}"
    end
    output
  end
end
class Ana
  def initialize(escaped_para_string)
    @escaped_para_string = escaped_para_string
    FileUtils.mkdir_p '../ergebnisse/sortiertewerte'
  end

  def makegraph(x_axis, params_arr, curve_param)
    File.delete "kfit.txt" if File.exists? "kfit.txt"
    makefiles = []
    filedata = sort_values_into_one_file(x_axis, params_arr, curve_param)
    makefiles = make_makefiles(filedata, x_axis, curve_param)
    [true, false].each do |bool|
      makefiles << sort_and_make_energy(params_arr, bool)
    end
    find_attr_breaking_point(filedata)
    #makefiles << kplot
    load_into_gnuplot(makefiles)
  end

  def find_attr_breaking_point(filedata)
    const_line = 0
    filedata.each do |tuple|
      filename = tuple[1]
      if tuple[0][0] == 0
        const_line = File.readlines(filename)[0].split[1].to_f
      else
        low = find_low(filename, const_line)
        puts "low inspect:"
        puts low.inspect
        high = find_high(filename, const_line)
        puts "high inspect:", high.inspect
        intersection = interpolate(const_line, low, high)
        puts "intersection at: attr = #{intersection}"
      end
      p tuple
      puts "----"
    end
  end
  # interpolate straight line with y = a*x + b
  # set offset to lower value, so you don't need to calc b
  # then calculate the sought after x with (y)/a = x
  #
  def interpolate(value, low_tuple, high_tuple)
    attr_low, p_low = low_tuple[0], low_tuple[1]
    attr_high, p_high = high_tuple[0], high_tuple[1]
    puts p_low.inspect,
    attr_low.inspect,
    p_high.inspect,
    attr_high.inspect
    a = (p_low - p_high) / (attr_low - attr_high)
    reduced_value = value - p_low
    return (reduced_value / a) + attr_low
  end

  def find_high(filename, value)
    prob = 0
    attraction = 0
    lines = File.readlines filename
    lines.each do |line|
      return [attraction, prob] if line.split[1].to_f <= value && attraction > 0
      prob = line.split[1].to_f
      attraction = line.split[0].to_f
    end
    raise "find high went wrong"
  end

  def find_low(filename, value)
    lines = File.readlines filename
    lines.each do |line|
      prob = line.split[1].to_f
      attraction = line.split[0].to_f
      return [attraction, prob] if prob <= value
    end
  end

  def load_into_gnuplot(makefiles)
    makefiles.each do |makefile|
      %x{gnuplot #{makefile}}
    end
  end

  def sort_and_make_energy(params_arr,outsidebool)
    curve_params = [:attraction]
    grouped_arr = params_arr.group_by{|outerhash| curve_params.map{|curve_param| outerhash[curve_param]}[0]}
    valuehash = {}
    grouped_arr.each do |grouper, x_arr|
      valuehash[grouper] = {"true" => {}, "false" => {}}

      x_arr.each do |sim_para_hash|
        para_string = @escaped_para_string % sim_para_hash
        a = IO.readlines("../ergebnisse/energy#{para_string}")
        a.each do |line|
          neighbour_count = line.split[0]
          bool = line.split[1]
          frequency = line.split[2]
          valuehash[grouper][bool][neighbour_count] = frequency
        end
        #a.each { |e| valuehash[grouper][e.split[0]] = e.split[1] }
      end
    end
    valuehash.each{|key, val| val.each{|key2, val2| val2.default_proc = proc{ |hash, key| hash[key] = "0" } }}
    attrs = valuehash.keys
    bools = valuehash.map{|key,val| val.keys}.flatten.uniq
    neighbour_counts = valuehash[attrs[0]][bools[0]].keys.sort

    sorted_data = "Title"
    attrs.each do |attri|
      sorted_data += "\t"
      sorted_data += attri.to_s
    end
    bools.each do |bool|
      next unless bool.to_s == outsidebool.to_s
      puts bool
      puts outsidebool
      neighbour_counts.each do |ncount|
        sorted_data += "\n"
        sorted_data += "#{ncount}#{bool}"
        valuehash.each do |key, val|
          sorted_data += "\t"
          sorted_data += val[bool][ncount]
        end
      end
    end
    filename = "../ergebnisse/sortiertewerte/energy#{outsidebool}"
    File.open(filename, "w+") do |file|
      file.write sorted_data
    end
helptext = ""
attrs.each_with_index do |att, idx|
  helptext += "'#{filename}' using #{idx + 2}:xticlabels(1) title columnhead, "
end
helptext[-2] = ""

    text = <<-END
clear
reset
unset key
set terminal pngcairo size 1024, 768
set output '../bilder/energy#{outsidebool}.png'
# Make the x axis labels easier to read.
set xtics rotate out
# Select histogram data
set key autotitle columnhead
set style data histogram
set xlabel 'Neighbour count and bound status'
set ylabel 'Probability'
# Give the bars a plain fill pattern, and draw a solid line around them.
set style fill solid border
set style histogram clustered
plot #{helptext}
    END

    output_file = "../ergebnisse/sortiertewerte/makeenergy#{outsidebool}"
    File.open(output_file,"w+") do |file|
      file.write(text)
    end
    output_file

  end
  #curve param means the parameter as in a family of curves
  def sort_values_into_one_file(x_axis, params_arr, curve_params )
    output = []

    grouped_arr = params_arr.group_by{|outerhash| curve_params.map{|curve_param| outerhash[curve_param]}}

    grouped_arr.each do |grouper, x_arr|
      values = ""
      x_arr.each do |sim_para_hash|
        para_string = @escaped_para_string % sim_para_hash
        a = IO.readlines("../ergebnisse/#{para_string}")

        values << "#{sim_para_hash[x_axis]}\t" << a[1]
      end
      constant_parameters = x_arr[0].reject{|key| [x_axis, curve_params].include?(key) }
      filename = "../ergebnisse/sortiertewerte/x#{x_axis}para#{curve_params.to_readable}#{grouper.to_readable}#{constant_parameters.to_readable}"
      output << [grouper, filename,x_arr[0]]
      File.open(filename, "w+") do |file|
        file.write values
      end

      k_fit(filename, constant_parameters[:crowder_percentage], constant_parameters[:attraction]) if [:crowder_percentage, :attraction] == curve_params
    end
    output
  end
  def kplot
    grouped = File.readlines("kfit.txt").
    map { |line| line.split }. #first is Value of K, second is crowder percentage, third is attraction
    group_by { |line| line[1]} #group by crowder_percentage
    keys = grouped.keys
    #seperate into different files because I
    #cannot figure out a nice way for gnuplot to do
    #curve families. probably there is, but you know: gnuplot :D
    grouped.each do |grouper, arr|
      string = ""
      arr.each do |tuple|
        string << "#{tuple[2]}, #{tuple[0]} \n"
      end
      File.write("K_for_C#{grouper}.txt",string)
    end

    helptext = ""
    keys.each do |grouper|
      helptext += "'K_for_C#{grouper}.txt' using 1:2 with lines title 'C#{grouper}', "
    end
    helptext[-2] = ""

    text = <<-END
clear
reset
unset key
set terminal pngcairo size 1024, 768
set output '../bilder/kplot.png'
set key outside tmargin
set xlabel 'Attr in kT'
set ylabel 'K'
plot #{helptext}
    END
  filename = "makefile_k"
  File.write(filename, text)
  return filename
end
  # fit function P(L)_{C,Att} = L / (L + K) and write K, C and Att in a file for later Splot
  def k_fit(filename, crowder_percentage, attraction)
    text = <<-END
set print 'kfit.txt' append;
f(x) = x / (k + x); fit f(x) '#{filename}' via k;
print k, #{crowder_percentage}, #{attraction};
    END
    File.open("temp.txt","w+") do |file|
      file.write(text)
    end

  %x{gnuplot temp.txt}
  end

  def make_makefiles(filedata, x_axis, curve_param)
    makefiles = []
    [{line: 2, abbr: "P", ylabel: "Bound Probability"},
    {line: 4, abbr: "B", ylabel: "Mean Bound Time"},
    {line: 5, abbr: "U", ylabel: "Mean Unbound Time"}].each do |hash|
      makefiles << make_makefile(filedata, x_axis, curve_param, hash)
    end
    # makefiles << make_makefile_p(filedata, x_axis, curve_param)
    # makefiles << make_makefile_b(filedata, x_axis, curve_param)
    # makefiles << make_makefile_u(filedata, x_axis, curve_param)
    return makefiles
  end
  def make_makefile(filedata, x_axis, curve_param, specify)
    helptext = ""
    constant_parameters = ""
    filedata.each do |tuple|
      curve_param_val = tuple[0]
      filename = tuple[1]
      constant_parameters = tuple[2]
      helptext += "'./#{filename}' u 1:#{specify[:line]} with lines title '#{curve_param} = #{curve_param_val}', "
    end
    helptext[-2] = ""
    text = <<-END
set terminal pngcairo size 1024, 768
set key outside tmargin
set logscale x
set xlabel '#{x_axis}'
set ylabel "#{specify[:ylabel]}"
set output '../bilder/#{specify[:abbr]}gegenx#{x_axis}para.png'
plot #{helptext}
    END
    output_file = "../ergebnisse/sortiertewerte/make#{specify[:abbr]}gegenx#{x_axis}para#{curve_param.to_readable}"
    File.open(output_file,"w+") do |file|
      file.write(text)
    end
    output_file
  end
end
