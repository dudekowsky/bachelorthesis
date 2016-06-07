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
    makefiles = []
    filedata = sort_values_into_one_file(x_axis, params_arr, curve_param)
    makefiles = make_makefiles(filedata, x_axis, curve_param)
    [true, false].each do |bool|
      makefiles << sort_and_make_energy(params_arr, bool)
    end
    load_into_gnuplot(makefiles)
    kplot
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
